<#
.SYNOPSIS
    Prints what the Play Console asks for when you register an upload key: the
    SHA-256 certificate fingerprint, and a PEM export of the certificate.

.DESCRIPTION
    Play has two ways of taking an upload key, and which one you get depends on
    the screen you are on:

      "Добавьте открытый ключ ... цифровой отпечаток сертификата SHA-256"
          -> paste the SHA-256 line this prints.

      Upload key reset / "Upload a certificate"
          -> upload the .pem file this writes.

    Neither is a secret: a fingerprint is a hash of the certificate and the PEM
    holds only the public half. The keystore and its password are the secret,
    and this script never copies either.

    Reads android/key.properties by default, so after create_upload_key.ps1 it
    needs no arguments.

.EXAMPLE
    .\tool\show_upload_key.ps1

.EXAMPLE
    .\tool\show_upload_key.ps1 -Keystore D:\keys\upload.jks -Alias upload
#>
[CmdletBinding()]
param(
    # Defaults to storeFile from android/key.properties.
    [string]$Keystore,
    # Defaults to keyAlias from android/key.properties.
    [string]$Alias,
    # Defaults to storePassword from android/key.properties; prompts if neither.
    [string]$StorePassword,
    # Where to write the PEM. Defaults to next to the keystore.
    [string]$PemPath,
    # Suppress the banner when called from create_upload_key.ps1.
    [switch]$NoHeader
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

trap {
    Write-Host ''
    Write-Host 'FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ''
    exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'release_common.ps1')

if (-not $Keystore -or -not $Alias -or -not $StorePassword) {
    $propsPath = Join-Path $repoRoot 'android\key.properties'
    if (-not (Test-Path $propsPath)) {
        throw "android/key.properties not found, and -Keystore / -Alias / -StorePassword were not all given. Create a key first: .\tool\create_upload_key.ps1"
    }
    $props = Read-JavaProperties $propsPath
    if (-not $Keystore) { $Keystore = $props['storeFile'] }
    if (-not $Alias) { $Alias = $props['keyAlias'] }
    if (-not $StorePassword) { $StorePassword = $props['storePassword'] }
}
if (-not (Test-Path $Keystore)) { throw "Keystore not found: $Keystore" }

$jdk = Resolve-JdkHome
$keytool = Join-Path $jdk 'bin\keytool.exe'
if (-not (Test-Path $keytool)) { throw "keytool not found at $keytool" }

if (-not $NoHeader) {
    Write-Section 'Upload key'
    Write-Detail 'keystore' $Keystore
    Write-Detail 'alias' $Alias
}

$info = Invoke-Capture $keytool @(
    '-list', '-v',
    '-keystore', $Keystore,
    '-alias', $Alias,
    '-storepass', $StorePassword
) 'keytool -list'

foreach ($pattern in @('^Owner:', 'Signature algorithm name:', 'Valid from:')) {
    $line = $info | Select-String -Pattern $pattern | Select-Object -First 1
    if ($line) { Write-Host "  $($line.Line.Trim())" }
}

$sha256 = $info | Select-String -Pattern '^\s+SHA256:\s*(\S+)' | Select-Object -First 1
if (-not $sha256) { throw 'keytool did not report a SHA-256 fingerprint.' }
$fingerprint = $sha256.Matches[0].Groups[1].Value

Write-Host ''
Write-Host '  SHA-256 fingerprint (paste this into the Play Console):'
Write-Host ''
Write-Host "  $fingerprint" -ForegroundColor Cyan
Write-Host ''

if (-not $PemPath) { $PemPath = [IO.Path]::ChangeExtension($Keystore, 'pem') }
# -rfc is the base64 PEM form; without it keytool writes DER, which the upload
# form rejects.
Invoke-Checked $keytool @(
    '-exportcert', '-rfc',
    '-keystore', $Keystore,
    '-alias', $Alias,
    '-storepass', $StorePassword,
    '-file', $PemPath
) 'keytool -exportcert'
Write-Detail 'certificate' $PemPath
Write-Host '  Upload that file on screens that ask for a certificate rather than'
Write-Host '  a fingerprint. It is the public half only, safe to send to Google.'
