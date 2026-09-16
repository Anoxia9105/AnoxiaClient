#!/usr/bin/env bash
# ============================================================
# AnoxiaClient 构建入口（Linux 版）
# 对应 Windows 版 tool_build.ps1 / tool_build.bat
#
# 流程（与 ps1 完全一致）：
#   1. 运行 ../AnoxiaProtocol/tool_generate_dart.sh 只生成 Dart 协议
#   2. flutter pub get（不会刷新 path 依赖，协议必须先生成）
#   3. 固定 wire bytes 协议测试（文件存在时才跑，已随 test/ 精简移除则跳过）
#   4. flutter build <Target>
#
# 用法（兼容 ps1 的 -Target / -Debug / -Wasm 写法）：
#   bash tool_build.sh                                  # 默认：web release
#   bash tool_build.sh -Target web -Wasm                 # Web Wasm release（与 ps1 示例一致）
#   bash tool_build.sh --target web --wasm
#   bash tool_build.sh -Target linux -Debug              # Linux debug 包
#   bash tool_build.sh -Target android                   # android 自动映射为 apk
#   FLUTTER_BIN=/opt/flutter/bin/flutter bash tool_build.sh -Target web -Wasm
# ============================================================

set -euo pipefail

PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

TARGET="web"
DEBUG=0
WASM=0

usage() {
  cat <<'EOF'
用法：tool_build.sh [-Target <target>] [-Debug] [-Wasm]

参数：
  -Target <target>   构建目标（默认 web），android 会自动映射为 apk
                     例：web / android / linux / windows / macos / ios
  -Debug             打 debug 包（默认 release）
  -Wasm              仅 web 有效：追加 --wasm（与 ps1 -Wasm 一致）
  -h, --help         显示本帮助

同时兼容 --target / --debug / --wasm / --target=web 写法。
环境变量：
  FLUTTER_BIN        flutter 可执行文件路径（默认 flutter）
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -Target|--target|-T)
      TARGET="${2:?缺少构建目标参数}"; shift 2 ;;
    -Target=*|--target=*)
      TARGET="${1#*=}"; shift ;;
    -Debug|--debug)
      DEBUG=1; shift ;;
    -Wasm|--wasm)
      WASM=1; shift ;;
    -h|--help|help)
      usage; exit 0 ;;
    *)
      echo "未知参数：$1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ "$DEBUG" -eq 1 ]]; then
  MODE="--debug"
else
  MODE="--release"
fi

GENERATE_SH="$PKG_ROOT/../AnoxiaProtocol/tool_generate_dart.sh"
if [[ ! -f "$GENERATE_SH" ]]; then
  echo "找不到协议生成脚本：$GENERATE_SH" >&2
  exit 1
fi

echo ">>> bash $GENERATE_SH"
bash "$GENERATE_SH"

# 切到工程根：flutter pub get / build 必须在本工程目录执行
cd "$PKG_ROOT"

echo ">>> $FLUTTER_BIN pub get"
"$FLUTTER_BIN" pub get

WIRE_TEST="$PKG_ROOT/test/framework/codec/im_packet_v6_test.dart"
if [[ -f "$WIRE_TEST" ]]; then
  echo ">>> $FLUTTER_BIN test $WIRE_TEST"
  "$FLUTTER_BIN" test "$WIRE_TEST"
else
  echo "跳过协议 wire 兼容测试：未找到 $WIRE_TEST"
fi

EXTRA=()
if [[ "$TARGET" == "web" ]]; then
  EXTRA+=("--no-tree-shake-icons")
  if [[ "$WASM" -eq 1 ]]; then
    EXTRA+=("--wasm")
  fi
fi

BUILD_TARGET="$TARGET"
if [[ "$TARGET" == "android" ]]; then
  BUILD_TARGET="apk"
fi

echo ">>> $FLUTTER_BIN build $BUILD_TARGET $MODE ${EXTRA[*]:-}"
"$FLUTTER_BIN" build "$BUILD_TARGET" "$MODE" "${EXTRA[@]:-}"

echo "flutter build $TARGET $MODE done."
