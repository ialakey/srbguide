<#
.SYNOPSIS
    Creates the Google Play upload key and wires it into android/key.properties.

.DESCRIPTION
    Run this ONCE. The keystore it produces is the only thing that lets you ship
    an update to the existing Play listing -- back it up somewhere offline before
    you upload anything. If it is lost, only Play support can reset the upload
    key.

    Play requires RSA 2048 or larger and a certificate that stays valid past
    2033. `-sigalg SHA256withRSA` is what makes the certificate itself SHA-256;
    tool/build_release.ps1 and the Release workflow both refuse to ship a key
    that is not.

.EXAMPLE
    .\tool\create_upload_key.ps1

.EXAMPLE
    .\tool\create_upload_key.ps1 -Keystore D:\keys\srbguide-upload.jks -Alias upload
#>
[CmdletBinding()]
param(
    # Where the .jks goes. Keep it OUT of the repository.
    [string]$Keystore = (Join-Path $env:USERPROFILE 'keys\srbguide-upload.jks'),
    [string]$Alias = 'upload',
    [string]$Dname = 'CN=Ilia Alakov, O=Serbia Guide, C=RS',
    # ~27 years. Play rejects certificates that expire before 2033.
    [int]$ValidityDays = 10000,
    # Write the base64 of the keystore next to it, for the GitHub secret.
    [switch]$PrintBase64
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Every failure here is "you got the setup wrong"; a PowerShell stack trace
# buries the sentence that says which.
trap {
    Write-Host ''
    Write-Host 'FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ''
    exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'release_common.ps1')

Write-Section 'Toolchain'
$jdk = Resolve-JdkHome
$keytool = Join-Path $jdk 'bin\keytool.exe'
if (-not (Test-Path $keytool)) { throw "keytool not found at $keytool" }
Write-Detail 'keytool' $keytool

Write-Section 'Keystore'
if (Test-Path $Keystore) {
    # Overwriting is unrecoverable: the old certificate is the only one Play
    # accepts for this listing.
    throw "$Keystore already exists. Refusing to touch it -- pass -Keystore for a different path, or reuse this one via android/key.properties."
}
$keystoreDir = Split-Path -Parent $Keystore
if ($keystoreDir -and -not (Test-Path $keystoreDir)) {
    New-Item -ItemType Directory -Path $keystoreDir | Out-Null
}
Write-Detail 'path' $Keystore
Write-Detail 'alias' $Alias
Write-Detail 'subject' $Dname

$secure1 = Read-Host -Prompt 'Keystore password (min 6 characters)' -AsSecureString
$secure2 = Read-Host -Prompt 'Repeat the password' -AsSecureString
$pass1 = ConvertFrom-SecureStringPlain $secure1
$pass2 = ConvertFrom-SecureStringPlain $secure2
if ($pass1 -ne $pass2) { throw 'The two passwords do not match.' }
if ($pass1.Length -lt 6) { throw 'keytool requires at least 6 characters.' }

# One password for both the store and the key: keytool -genkeypair with
# -storetype PKCS12 does not support a separate key password anyway.
Invoke-Checked $keytool @(
    '-genkeypair',
    '-alias', $Alias,
    '-keyalg', 'RSA',
    '-keysize', '4096',
    '-sigalg', 'SHA256withRSA',
    '-validity', "$ValidityDays",
    '-keystore', $Keystore,
    '-storetype', 'PKCS12',
    '-dname', $Dname,
    '-storepass', $pass1,
    '-keypass', $pass1
) 'keytool -genkeypair'

Write-Section 'Certificate'
$info = & $keytool -list -v -keystore $Keystore -alias $Alias -storepass $pass1
if ($LASTEXITCODE -ne 0) { throw 'keytool -list failed' }
$info | Select-String -Pattern 'Signature algorithm name:|Valid from:|^\s+SHA256:' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
if (-not ($info | Select-String -Pattern 'Signature algorithm name:\s*SHA256with')) {
    throw 'The generated certificate is not SHA-256. Play will reject it.'
}

Write-Section 'android/key.properties'
$propsPath = Join-Path $repoRoot 'android\key.properties'
if (Test-Path $propsPath) {
    throw "$propsPath already exists; not overwriting. Point it at the new keystore by hand if that is what you want."
}
# Gradle reads this file as a java.util.Properties, where `\` starts an escape
# and `:` can separate a key from its value. The replacement string is taken
# literally, so '\\' here means the two characters Properties decodes back into
# one backslash.
$escapedStore = $Keystore -replace '\\', '\\' -replace ':', '\:'
$propsText = @(
    "storeFile=$escapedStore",
    "storePassword=$pass1",
    "keyAlias=$Alias",
    "keyPassword=$pass1"
) -join "`n"
# Properties.load(InputStream) decodes ISO-8859-1, so a UTF-8 BOM would be read
# as three characters glued to the first key and `storeFile` would come back
# null. Write plain ASCII, escaping anything above it the way Properties expects.
$ascii = -join ($propsText.ToCharArray() | ForEach-Object {
    if ([int]$_ -lt 128) { $_ } else { '\u{0:x4}' -f [int]$_ }
})
[IO.File]::WriteAllText($propsPath, $ascii + "`n", (New-Object Text.UTF8Encoding $false))
Write-Detail 'written' $propsPath
Write-Host '  (git-ignored; it holds the passwords in clear text)'

if ($PrintBase64) {
    Write-Section 'ANDROID_KEYSTORE_BASE64'
    $b64Path = "$Keystore.base64.txt"
    [Convert]::ToBase64String([IO.File]::ReadAllBytes($Keystore)) | Set-Content -Path $b64Path -Encoding ascii -NoNewline
    Write-Detail 'written' $b64Path
    Write-Host '  Paste its contents into the GitHub secret, then delete the file.'
}

# Play asks for the key one of two ways depending on the screen: a SHA-256
# fingerprint to paste, or a PEM certificate to upload. Produce both.
Write-Section 'For the Play Console'
& (Join-Path $PSScriptRoot 'show_upload_key.ps1') -Keystore $Keystore -Alias $Alias -StorePassword $pass1 -NoHeader

Write-Section 'Next'
Write-Host @"
  1. Back up $Keystore and its password offline. Losing them means you can
     never update the existing Play listing.
  2. Register the key with Play (fingerprint or PEM, printed above).
  3. Build a release:  .\tool\build_release.ps1
  4. For CI, add the four repository secrets listed in docs/RELEASE.md
     (re-run this script with -PrintBase64 to get ANDROID_KEYSTORE_BASE64).
"@
