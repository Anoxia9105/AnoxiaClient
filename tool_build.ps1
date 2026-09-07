param(
    [string]$Target = 'web',
    [switch]$Debug,
    [switch]$Wasm
)

$ErrorActionPreference = 'Stop'

$PKG_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FLUTTER_BIN = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } else { 'flutter' }
$Mode = if ($Debug) { '--debug' } else { '--release' }

$rc = 1
try {
    & (Join-Path $PKG_ROOT '../AnoxiaProtocol/tool_generate_dart.ps1')
    Write-Host ">>> $FLUTTER_BIN pub get"
    & $FLUTTER_BIN pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Host "flutter pub get failed (rc=$LASTEXITCODE)"
        $rc = $LASTEXITCODE
    } else {
        & $FLUTTER_BIN test test/framework/codec/im_packet_v6_test.dart
        if ($LASTEXITCODE -ne 0) {
            throw "Protocol wire compatibility tests failed (rc=$LASTEXITCODE)"
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
    }
} finally {}

exit $rc
