param(
    [string]$Target = 'web',
    [switch]$Debug,
    [switch]$Wasm
)

$ErrorActionPreference = 'Stop'

$PKG_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FLUTTER_BIN = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } else { 'flutter' }
$PUBSPEC = Join-Path $PKG_ROOT 'pubspec.yaml'
$Mode = if ($Debug) { '--debug' } else { '--release' }

function Strip-Fonts {
    param([string]$Path)
    $lines = Get-Content -Path $Path -Encoding UTF8
    $out = @()
    $inFonts = $false
    foreach ($line in $lines) {
        if ($inFonts) {
            $twoSpace = $line.Length -ge 2 -and $line.Substring(0, 2) -eq '  '
            $threeSpace = $line.StartsWith('   ')
            if ($twoSpace -and -not $threeSpace -and $line.Trim().Length -gt 0) {
                $inFonts = $false
            } else {
                continue
            }
        }
        if ($line.TrimEnd() -eq '  fonts:') {
            $inFonts = $true
            continue
        }
        $out += $line
    }
    [System.IO.File]::WriteAllText($Path, ($out -join "`r`n"), [System.Text.Encoding]::UTF8)
}

$backup = $null
if ($Target -eq 'web') {
    $backup = Get-Content -Path $PUBSPEC -Raw -Encoding UTF8
    Strip-Fonts -Path $PUBSPEC
    $newText = Get-Content -Path $PUBSPEC -Raw
    if ($newText -eq $backup) {
        $backup = $null
    } else {
        Write-Host '>>> pubspec.yaml fonts section temporarily removed (web build)'
    }
}

try {
    Write-Host ">>> $FLUTTER_BIN pub get"
    & $FLUTTER_BIN pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Host "flutter pub get failed (rc=$LASTEXITCODE)"
        exit $LASTEXITCODE
    }

    $extra = @()
    if ($Target -eq 'web') {
        $extra += '--no-tree-shake-icons'
        if ($Wasm) { $extra += '--wasm' }
    }

    $buildTarget = $Target
    if ($Target -eq 'android') { $buildTarget = 'apk' }

    Write-Host ">>> $FLUTTER_BIN build $buildTarget $Mode $extra"
    & $FLUTTER_BIN build $buildTarget $Mode @extra
    $rc = $LASTEXITCODE
    Write-Host "flutter build $Target $Mode rc=$rc"
    exit $rc
} finally {
    if ($null -ne $backup) {
        [System.IO.File]::WriteAllText($PUBSPEC, $backup)
        Write-Host '>>> pubspec.yaml restored (fonts section)'
    }
}
