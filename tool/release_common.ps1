<#
    Shared helpers for tool/build_release.ps1 and tool/create_upload_key.ps1.
    Dot-source it; it defines functions only.

    Targets Windows PowerShell 5.1, so: no `&&`/`||`, no ternary, no `??`.
#>

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host ''
    Write-Host "== $Title" -ForegroundColor Cyan
}

function Write-Detail {
    param([string]$Label, [string]$Value)
    Write-Host ("  {0,-14} {1}" -f $Label, $Value)
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  OK  $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  !!  $Message" -ForegroundColor Yellow
}

<#
    Runs a native executable and throws on a non-zero exit code.

    stderr is deliberately left unredirected: `2>&1` on a native command in
    PowerShell 5.1 wraps each stderr line in an ErrorRecord and reports failure
    even when the exit code was 0.
#>
function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$Arguments = @(),
        [string]$What
    )
    if (-not $What) { $What = Split-Path -Leaf $Exe }
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$What failed with exit code $LASTEXITCODE"
    }
}

# Same, but returns stdout as a string array instead of streaming it.
function Invoke-Capture {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$Arguments = @(),
        [string]$What
    )
    if (-not $What) { $What = Split-Path -Leaf $Exe }
    $output = & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        $output | ForEach-Object { Write-Host $_ }
        throw "$What failed with exit code $LASTEXITCODE"
    }
    return @($output)
}

function ConvertFrom-SecureStringPlain {
    param([Parameter(Mandatory)][System.Security.SecureString]$Secure)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

# Reads a java.util.Properties-style file into a hashtable. Enough for
# local.properties and key.properties: `key=value`, `#`/`!` comments,
# backslash escapes in the value.
function Read-JavaProperties {
    param([Parameter(Mandatory)][string]$Path)
    $map = @{}
    foreach ($line in (Get-Content -Path $Path -Encoding utf8)) {
        $trimmed = $line.Trim()
        if (-not $trimmed) { continue }
        if ($trimmed.StartsWith('#') -or $trimmed.StartsWith('!')) { continue }
        $sep = $trimmed.IndexOf('=')
        if ($sep -lt 1) { continue }
        $key = $trimmed.Substring(0, $sep).Trim()
        $value = $trimmed.Substring($sep + 1).Trim()
        # Undo the escaping Gradle's Properties loader would apply.
        $value = $value -replace '\\:', ':' -replace '\\\\', '\'
        $map[$key] = $value
    }
    return $map
}

<#
    Finds the JDK that owns keytool/jarsigner, preferring the one Flutter is
    pinned to. Android Studio's bundled JBR is deliberately not used -- see
    SETUP.md.
#>
function Resolve-JdkHome {
    $candidates = New-Object System.Collections.Generic.List[string]

    $settingsPath = Join-Path $env:USERPROFILE '.flutter_settings'
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content -Raw -Path $settingsPath | ConvertFrom-Json
            if ($settings.PSObject.Properties.Name -contains 'jdk-dir') {
                $candidates.Add($settings.'jdk-dir')
            }
        } catch {
            # A malformed settings file is not worth failing the build over.
        }
    }
    if ($env:JAVA_HOME) { $candidates.Add($env:JAVA_HOME) }
    $candidates.Add('D:\dev\jdk21')

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path (Join-Path $candidate 'bin\keytool.exe'))) {
            return $candidate
        }
    }
    $onPath = Get-Command keytool.exe -ErrorAction SilentlyContinue
    if ($onPath) { return (Split-Path -Parent (Split-Path -Parent $onPath.Source)) }

    throw 'No JDK found. Set JAVA_HOME, or run `flutter config --jdk-dir <path>` (SETUP.md pins Temurin 21).'
}

function Resolve-FlutterExe {
    param([string]$RepoRoot)

    $localProps = Join-Path $RepoRoot 'android\local.properties'
    if (Test-Path $localProps) {
        $props = Read-JavaProperties $localProps
        if ($props.ContainsKey('flutter.sdk')) {
            $fromProps = Join-Path ($props['flutter.sdk'] -replace '/', '\') 'bin\flutter.bat'
            if (Test-Path $fromProps) { return $fromProps }
        }
    }
    $onPath = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    if (Test-Path 'D:\dev\flutter\bin\flutter.bat') { return 'D:\dev\flutter\bin\flutter.bat' }

    throw 'flutter.bat not found. Put the Flutter SDK on PATH or set flutter.sdk in android/local.properties.'
}

function Resolve-AndroidSdk {
    param([string]$RepoRoot)

    $candidates = New-Object System.Collections.Generic.List[string]
    $localProps = Join-Path $RepoRoot 'android\local.properties'
    if (Test-Path $localProps) {
        $props = Read-JavaProperties $localProps
        if ($props.ContainsKey('sdk.dir')) { $candidates.Add(($props['sdk.dir'] -replace '/', '\')) }
    }
    if ($env:ANDROID_SDK_ROOT) { $candidates.Add($env:ANDROID_SDK_ROOT) }
    if ($env:ANDROID_HOME) { $candidates.Add($env:ANDROID_HOME) }
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Android\Sdk'))

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path (Join-Path $candidate 'build-tools'))) { return $candidate }
    }
    throw 'Android SDK not found. Set ANDROID_SDK_ROOT or sdk.dir in android/local.properties.'
}

# Newest build-tools directory, by version rather than by name -- 36.0.0 has to
# sort above 9.0.0.
function Resolve-ApkSigner {
    param([Parameter(Mandatory)][string]$AndroidSdk)

    $buildTools = @(Get-ChildItem -Path (Join-Path $AndroidSdk 'build-tools') -Directory |
        Sort-Object -Property @{ Expression = {
            $parsed = $null
            if ([Version]::TryParse($_.Name, [ref]$parsed)) { $parsed } else { [Version]'0.0.0' }
        } })
    for ($i = $buildTools.Count - 1; $i -ge 0; $i--) {
        $candidate = Join-Path $buildTools[$i].FullName 'apksigner.bat'
        if (Test-Path $candidate) { return $candidate }
    }
    throw "No apksigner.bat under $AndroidSdk\build-tools. Install build-tools with sdkmanager."
}
