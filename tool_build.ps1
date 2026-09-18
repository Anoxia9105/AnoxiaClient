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
        $wireTest = Join-Path $PKG_ROOT 'test/framework/codec/im_packet_v6_test.dart'
        if (Test-Path $wireTest) {
            & $FLUTTER_BIN test $wireTest
            if ($LASTEXITCODE -ne 0) {
                throw "Protocol wire compatibility tests failed (rc=$LASTEXITCODE)"
            }
        } else {
            Write-Host "跳过协议 wire 兼容测试：未找到 $wireTest"
        }
        $extra = @()
        if ($Target -eq 'web') {
            $extra += '--no-tree-shake-icons'
            if ($Wasm) { $extra += '--wasm' }
        }

        # Google OAuth Client ID（公开信息）：经环境变量 GOOGLE_OAUTH_CLIENT_ID 传入，
        # 透传为 --dart-define 烘焙进产物（桌面端登录按钮靠它显示）。
        # 为空则不传参，前端自动隐藏 Google 登录入口，不影响密码登录。
        # 例：$env:GOOGLE_OAUTH_CLIENT_ID='xxx.apps.googleusercontent.com'
        $dartDefines = @()
        if ($env:GOOGLE_OAUTH_CLIENT_ID) {
            $dartDefines += "--dart-define=GOOGLE_OAUTH_CLIENT_ID=$($env:GOOGLE_OAUTH_CLIENT_ID)"
        }

        $buildTarget = $Target
        if ($Target -eq 'android') { $buildTarget = 'apk' }

        Write-Host ">>> $FLUTTER_BIN build $buildTarget $Mode $extra $dartDefines"
        & $FLUTTER_BIN build $buildTarget $Mode @extra @dartDefines
        $rc = $LASTEXITCODE
        Write-Host "flutter build $Target $Mode rc=$rc"
    }
} finally {}

exit $rc
