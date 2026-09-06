<#
.SYNOPSIS
    Builds the signed App Bundle (for Google Play) and APK (for sideloading),
    then proves the signature is what Play expects.

.DESCRIPTION
    This is the only place the upload key is used: .github/workflows/release.yml
    holds no signing secrets and builds a debug-signed APK for sideloading, so
    the Play artifact is made here. What it does:

      1. resolve the toolchain (Flutter, JDK, Android SDK build-tools);
      2. refuse to run without android/key.properties -- a debug-signed upload
         is rejected by Play and cannot be upgraded to a real key afterwards;
      3. verify the upload key itself is SHA256withRSA;
      4. flutter pub get / analyze / test / validate the bundled guide;
      5. build the AAB and the APK at an explicit version;
      6. apksigner: APK Signature Scheme v2, a SHA-256 certificate digest, and
         not the Android debug certificate;
      7. jarsigner -verify on the AAB;
      8. assert the merged manifest still targets SDK 36;
      9. copy both artifacts into dist/ under their version, with SHA-256 sums.

    Versions come from `version:` in pubspec.yaml unless overridden here.

.EXAMPLE
    .\tool\build_release.ps1
    # 2.0.0+14 straight from pubspec.yaml

.EXAMPLE
    .\tool\build_release.ps1 -VersionName 2.0.1 -BuildNumber 14

.EXAMPLE
    .\tool\build_release.ps1 -SkipChecks -SkipClean
    # fast rebuild while iterating; never for the build you actually upload
#>
[CmdletBinding()]
param(
    # Play's versionName, e.g. 2.0.0. Defaults to pubspec.yaml.
    [string]$VersionName,
    # Play's versionCode. Must be higher than anything already uploaded.
    [int]$BuildNumber = 0,
    # The lowest versionCode Play will accept next. Bump after each upload.
    [int]$PublishedBuildNumber = 12,
    # Skip analyze/test/guide validation. Not for a build you will upload.
    [switch]$SkipChecks,
    # Reuse the previous build's intermediates.
    [switch]$SkipClean,
    # Build only the .aab (what Play wants) and skip the .apk.
    [switch]$BundleOnly,
    # Build only the .apk (sideloading, manual QA) and skip the .aab.
    [switch]$ApkOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'release_common.ps1')

if ($BundleOnly -and $ApkOnly) { throw 'Pass at most one of -BundleOnly / -ApkOnly.' }
$buildBundle = -not $ApkOnly
$buildApk = -not $BundleOnly

Push-Location $repoRoot
$started = Get-Date
$failure = $null
try {

# ---------------------------------------------------------------- toolchain --
Write-Section 'Toolchain'
$flutter = Resolve-FlutterExe -RepoRoot $repoRoot
$jdk = Resolve-JdkHome
$androidSdk = Resolve-AndroidSdk -RepoRoot $repoRoot
$apksigner = Resolve-ApkSigner -AndroidSdk $androidSdk
$dart = Join-Path (Split-Path -Parent $flutter) 'dart.bat'
$keytool = Join-Path $jdk 'bin\keytool.exe'
$jarsigner = Join-Path $jdk 'bin\jarsigner.exe'
foreach ($exe in @($dart, $keytool, $jarsigner)) {
    if (-not (Test-Path $exe)) { throw "Not found: $exe" }
}
# apksigner.bat looks for java through JAVA_HOME and fails outright without it.
# Flutter is pinned to its own JDK (SETUP.md), which need not be on PATH, so
# hand the same one to the SDK tools for this process only.
$env:JAVA_HOME = $jdk
Write-Detail 'flutter' $flutter
Write-Detail 'jdk' $jdk
Write-Detail 'android sdk' $androidSdk
Write-Detail 'apksigner' $apksigner

# ------------------------------------------------------------------ signing --
Write-Section 'Signing key'
$keyPropsPath = Join-Path $repoRoot 'android\key.properties'
if (-not (Test-Path $keyPropsPath)) {
    # Without this file build.gradle.kts falls back to the debug config on
    # purpose, so that `flutter run --release` keeps working. That fallback must
    # never reach Play.
    throw @"
android/key.properties is missing, so a release build here would be signed with
the Android debug key and rejected by Play.

  First release ever:  .\tool\create_upload_key.ps1
  Existing key:        write android/key.properties as

      storeFile=D:\\path\\to\\upload-keystore.jks
      storePassword=...
      keyAlias=upload
      keyPassword=...
"@
}
$keyProps = Read-JavaProperties $keyPropsPath
foreach ($required in @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')) {
    if (-not $keyProps.ContainsKey($required) -or -not $keyProps[$required]) {
        throw "android/key.properties has no value for '$required'."
    }
}
$storeFile = $keyProps['storeFile']
if (-not [IO.Path]::IsPathRooted($storeFile)) {
    # Gradle resolves this one through the :app project, so a relative path is
    # relative to android/app -- easy to get wrong. Accept it, but say so.
    Write-Warn "storeFile is relative; Gradle resolves it against android/app. An absolute path is safer."
    $storeFile = Join-Path (Join-Path $repoRoot 'android\app') $storeFile
}
if (-not (Test-Path $storeFile)) { throw "Keystore not found: $storeFile" }
Write-Detail 'keystore' $storeFile
Write-Detail 'alias' $keyProps['keyAlias']

$keyInfo = Invoke-Capture $keytool @(
    '-list', '-v',
    '-keystore', $storeFile,
    '-alias', $keyProps['keyAlias'],
    '-storepass', $keyProps['storePassword']
) 'keytool -list'
if (-not ($keyInfo | Select-String -Pattern 'Signature algorithm name:\s*SHA256with')) {
    throw 'The upload key is not SHA256withRSA. Regenerate it (see docs/RELEASE.md); Play will not accept it.'
}
$keyFingerprint = ($keyInfo | Select-String -Pattern '^\s+SHA256:\s*(\S+)' | Select-Object -First 1)
$keyFingerprintValue = ''
Write-Ok 'key certificate is SHA-256'
if ($keyFingerprint) {
    $keyFingerprintValue = $keyFingerprint.Matches[0].Groups[1].Value
    Write-Detail 'fingerprint' $keyFingerprintValue
}
$expiry = ($keyInfo | Select-String -Pattern 'until:' | Select-Object -First 1)
if ($expiry) { Write-Detail 'validity' $expiry.Line.Trim() }

# ------------------------------------------------------------------ version --
Write-Section 'Version'
$pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
$pubspecVersion = (Select-String -Path $pubspecPath -Pattern '^version:\s*(\S+)\s*$' |
    Select-Object -First 1)
if (-not $pubspecVersion) { throw 'No version: line in pubspec.yaml.' }
$pubspecValue = $pubspecVersion.Matches[0].Groups[1].Value
$parts = $pubspecValue.Split('+')
if (-not $VersionName) { $VersionName = $parts[0] }
if ($BuildNumber -le 0) {
    if ($parts.Count -lt 2) { throw "pubspec version '$pubspecValue' has no +buildNumber; pass -BuildNumber." }
    $BuildNumber = [int]$parts[1]
}
Write-Detail 'pubspec' $pubspecValue
Write-Detail 'versionName' $VersionName
Write-Detail 'versionCode' $BuildNumber
if ($BuildNumber -le $PublishedBuildNumber) {
    # Play rejects a duplicate versionCode after the upload, several minutes in.
    throw "versionCode $BuildNumber is not above $PublishedBuildNumber, which is already on Play. Bump the version: line in pubspec.yaml, or pass -PublishedBuildNumber if that number is stale."
}

# ------------------------------------------------------------------- checks --
if (-not $SkipClean) {
    Write-Section 'Clean'
    Invoke-Checked $flutter @('clean') 'flutter clean'
}

Write-Section 'Dependencies'
Invoke-Checked $flutter @('pub', 'get') 'flutter pub get'

if ($SkipChecks) {
    Write-Section 'Checks'
    Write-Warn 'skipped by -SkipChecks; do not upload this build'
} else {
    Write-Section 'Analyze'
    Invoke-Checked $flutter @('analyze') 'flutter analyze'

    Write-Section 'Test'
    # `live` tests hit the real exchange-office sites; a third-party outage
    # should not block a release. parsers.yml runs them daily instead.
    Invoke-Checked $flutter @('test', '--exclude-tags', 'live') 'flutter test'

    Write-Section 'Guide content'
    Invoke-Checked $dart @('run', 'tool/validate_guide.dart') 'validate_guide'
}

$versionArgs = @('--release', "--build-name=$VersionName", "--build-number=$BuildNumber")
$aabPath = Join-Path $repoRoot 'build\app\outputs\bundle\release\app-release.aab'
$apkPath = Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-release.apk'

# -------------------------------------------------------------------- build --
if ($buildBundle) {
    Write-Section 'Build App Bundle'
    Invoke-Checked $flutter (@('build', 'appbundle') + $versionArgs) 'flutter build appbundle'
    if (-not (Test-Path $aabPath)) { throw "Expected $aabPath" }
}
if ($buildApk) {
    Write-Section 'Build APK'
    Invoke-Checked $flutter (@('build', 'apk') + $versionArgs) 'flutter build apk'
    if (-not (Test-Path $apkPath)) { throw "Expected $apkPath" }
}

# ------------------------------------------------------------------- verify --
$certLines = @()
if ($buildApk) {
    Write-Section 'Verify APK signature'
    $sig = Invoke-Capture $apksigner @('verify', '--verbose', '--print-certs', $apkPath) 'apksigner verify'
    $sig | ForEach-Object { Write-Host "  $_" }

    # v2/v3 are the SHA-256 whole-file schemes; v1 alone is the old JAR
    # signing Play no longer accepts on its own.
    if (-not ($sig | Select-String -SimpleMatch 'Verified using v2 scheme (APK Signature Scheme v2): true')) {
        throw 'APK is not signed with APK Signature Scheme v2.'
    }
    if (-not ($sig | Select-String -Pattern 'Signer #1 certificate SHA-256 digest')) {
        throw 'apksigner reported no SHA-256 certificate digest.'
    }
    if ($sig | Select-String -Pattern 'CN=Android Debug') {
        throw 'APK was signed with the Android debug key. Check android/key.properties.'
    }
    $certLines = @($sig | Select-String -Pattern 'Verified using|Signer #1 certificate (DN|SHA-256)' |
        ForEach-Object { $_.Line.Trim() })
    Write-Ok 'v2 scheme, SHA-256 certificate, not the debug key'
}

if ($buildBundle) {
    Write-Section 'Verify App Bundle signature'
    # An .aab is a JAR, so jarsigner is the right tool -- apksigner does not
    # read bundles. `-strict` is deliberately absent: an app-signing certificate
    # is self-signed by definition, which -strict counts as a severe warning and
    # exits non-zero for, so with it the check could only ever fail.
    $bundleSig = & $jarsigner '-verify' '-verbose:summary' $aabPath
    $jarsignerExit = $LASTEXITCODE
    $bundleSig | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" }
    if ($jarsignerExit -ne 0) { throw "jarsigner -verify failed with exit code $jarsignerExit" }
    if (-not ($bundleSig | Select-String -SimpleMatch 'jar verified')) {
        throw 'jarsigner did not report the bundle as verified.'
    }
    if ($bundleSig | Select-String -Pattern 'CN=Android Debug') {
        throw 'The bundle was signed with the Android debug key.'
    }
    Write-Ok 'bundle verifies'
}

Write-Section 'Manifest'
$manifest = Join-Path $repoRoot 'build\app\intermediates\packaged_manifests\release\processReleaseManifestForPackage\AndroidManifest.xml'
if (Test-Path $manifest) {
    $manifestText = Get-Content -Raw -Path $manifest
    foreach ($m in ([regex]'android:(minSdkVersion|targetSdkVersion|versionCode|versionName)="[^"]*"').Matches($manifestText)) {
        Write-Host "  $($m.Value)"
    }
    if ($manifestText -notmatch 'android:targetSdkVersion="36"') {
        throw 'The merged manifest does not target SDK 36, which Play requires.'
    }
    Write-Ok 'targets Android 16 (API 36)'
} else {
    Write-Warn "merged manifest not found at $manifest; skipped the targetSdk check"
}

# --------------------------------------------------------------------- dist --
Write-Section 'Artifacts'
$distDir = Join-Path $repoRoot 'dist'
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
$stamp = "$VersionName+$BuildNumber"
$copied = @()
if ($buildBundle) { $copied += @{ From = $aabPath; To = Join-Path $distDir "srbguide-$stamp.aab" } }
if ($buildApk) { $copied += @{ From = $apkPath; To = Join-Path $distDir "srbguide-$stamp.apk" } }
foreach ($item in $copied) {
    Copy-Item -Path $item.From -Destination $item.To -Force
    $hash = (Get-FileHash -Path $item.To -Algorithm SHA256).Hash
    "$hash  $(Split-Path -Leaf $item.To)" | Set-Content -Path "$($item.To).sha256" -Encoding ascii
    $size = '{0:N1} MB' -f ((Get-Item $item.To).Length / 1MB)
    Write-Detail (Split-Path -Leaf $item.To) $size
}

Write-Section 'Done'
Write-Detail 'elapsed' ('{0:mm\:ss}' -f ([TimeSpan]((Get-Date) - $started)))
Write-Detail 'output' $distDir
if ($certLines.Count -gt 0) {
    Write-Host ''
    $certLines | ForEach-Object { Write-Host "  $_" }
}
if ($keyFingerprintValue) {
    # The Play Console shows the registered upload key in this colon-separated
    # form, so print it the same way rather than making you re-derive it.
    Write-Host ''
    Write-Host '  Upload key SHA-256 — must match "Upload key certificate" in the Play Console:'
    Write-Host "  $keyFingerprintValue"
}
Write-Host @"

  Upload dist\srbguide-$stamp.aab to Play Console -> Production -> Create new release.
  The APK is for sideloading and manual QA; Play takes the bundle.

  What's new, ready to paste:
    docs/play/whats-new-ru-RU.txt
    docs/play/whats-new-en-US.txt

  After Play accepts the upload:
    - raise -PublishedBuildNumber's default in tool/build_release.ps1 to $BuildNumber
    - git tag v$VersionName; git push origin v$VersionName
"@
if ($SkipChecks) { Write-Warn 'built with -SkipChecks: analyze/tests/guide validation did not run' }

} catch {
    # These are all "you got the setup wrong" errors; a PowerShell stack trace
    # buries the sentence that says which one.
    $failure = $_
} finally {
    Pop-Location
}

if ($failure) {
    Write-Host ''
    Write-Host "BUILD FAILED" -ForegroundColor Red
    Write-Host $failure.Exception.Message -ForegroundColor Red
    Write-Host ''
    exit 1
}
