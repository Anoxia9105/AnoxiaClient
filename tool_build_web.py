import os
import shutil
import subprocess
import sys

# 项目根目录默认取本脚本所在目录，换电脑 / CI 无需任何配置即可运行；
# 仅在需要指向其它目录时才用环境变量覆盖。
PKG_ROOT = os.environ.get(
    'ANOXIA_WEB_PKG_ROOT', os.path.dirname(os.path.abspath(__file__))
)

# Flutter SDK 默认从 PATH 查找（shutil.which 在 Windows 下也能解析 flutter.bat），
# 仅在 PATH 不含 flutter 时才用环境变量 FLUTTER_BIN 覆盖显式指定。
FLUTTER_BIN = os.environ.get('FLUTTER_BIN', shutil.which('flutter') or 'flutter')


def run(args):
    # args 为 flutter 子命令列表，例如 ['pub', 'get']。
    # 不使用 shell=True：用参数数组交给 subprocess 正确转义，避免带空格的
    # SDK 路径（如 "Program Files"）被错误拆分。
    # Windows 下 flutter SDK 实为 flutter.bat，CreateProcess 无法直执行 .bat，
    # 故通过 cmd /c 包裹；cmd /c 之后的参数仍由 subprocess 正确加引号。
    cmd = [FLUTTER_BIN] + args
    if FLUTTER_BIN.lower().endswith('.bat'):
        cmd = ['cmd', '/c'] + cmd
    print('>>> ' + ' '.join(cmd))
    p = subprocess.run(cmd, cwd=PKG_ROOT, shell=False)
    return p.returncode


def main():
    # 条件导入（lib/platform/shims/*）已隔离原生插件，flutter build web 在完整
    # pubspec 下即可成功，无需剥离 / 恢复依赖——那套流程既会污染原生构建环境，又
    # 会把本机路径硬编码带进来。这里直接 pub get + build web，失败则如实返回非零。
    rc = run(['pub', 'get'])
    if rc != 0:
        print('flutter pub get failed (rc=%d)' % rc)
        return rc
    rc = run(['build', 'web', '--release'])
    print('flutter build web rc=%d' % rc)
    return rc


if __name__ == '__main__':
    sys.exit(main())
