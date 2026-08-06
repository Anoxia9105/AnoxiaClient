import os
import shutil
import subprocess
import sys

# 项目根目录默认取本脚本所在目录，换电脑/ CI 无需任何配置即可运行。
# 仅在需要指向其它目录时才用环境变量覆盖。
PKG_ROOT = os.environ.get(
    'ANOXIA_WEB_PKG_ROOT', os.path.dirname(os.path.abspath(__file__))
)

# Flutter SDK 默认在 PATH 查找（shutil.which 在 Windows 下也能解析 flutter.bat），
# 仅在 PATH 不含 flutter 时才用环境变量 FLUTTER_BIN 覆盖显式指定。
FLUTTER_BIN = os.environ.get('FLUTTER_BIN', shutil.which('flutter') or 'flutter')

PUBSPEC = os.path.join(PKG_ROOT, 'pubspec.yaml')


def run(args):
    # args 是 flutter 子命令列表，例如 ['pub', 'get']。
    # 不使用 shell=True：用参数数组交给 subprocess 正确转义，避免带空格的
    # SDK 路径（如 "Program Files"）被错误拆分。
    # Windows 下 flutter SDK 实为 flutter.bat，CreateProcess 无法直接执行 .bat，
    # 故通过 cmd /c 包裹；cmd /c 之后的参数仍由 subprocess 正确加引号。
    cmd = [FLUTTER_BIN] + args
    if FLUTTER_BIN.lower().endswith('.bat'):
        cmd = ['cmd', '/c'] + cmd
    print('>>> ' + ' '.join(cmd))
    p = subprocess.run(cmd, cwd=PKG_ROOT, shell=False)
    return p.returncode


def strip_fonts_section(text):
    """移除 pubspec 中 flutter: 下的 fonts: 声明段。

    Web 构建不打包 HarmonyOS.ttf（约 8MB）：该字体仅原生端使用，且引擎在
    初始化阶段会无条件下载 FontManifest.json 里声明的全部字体，即使代码
    不再引用也会被浏览器拉取。原生构建不经过本脚本，pubspec 保持完整。
    """
    lines = text.splitlines(keepends=True)
    out = []
    in_fonts = False
    for line in lines:
        if in_fonts:
            # 2 空格缩进 = flutter: 下的顶层 key（fonts: 块结束）；
            # 更深的缩进（4/6/8 空格）是 fonts 列表项，继续丢弃。
            if line[:2] == '  ' and not line.startswith('   ') and line.strip():
                in_fonts = False
            else:
                continue
        if line.rstrip() == '  fonts:':
            in_fonts = True
            continue
        out.append(line)
    return ''.join(out)


def main():
    # 条件导入（lib/platform/shims/*）已隔离原生插件，flutter build web 在完整
    # pubspec 下即可成功，无需剥离 / 恢复依赖——那套流程既会污染原生构建环境，
    # 也会把本机路径硬编码带进来。这里直接 pub get + build web，失败则如实返回非零。
    #
    # 唯一例外：build 前临时从 pubspec 去掉 flutter:fonts: 段（Web 端不使用
    # 内置字体），避免 8MB HarmonyOS.ttf 被下载；构建结束（含失败路径）恢复。
    backup = None
    try:
        with open(PUBSPEC, 'r', encoding='utf-8') as f:
            original = f.read()
        stripped = strip_fonts_section(original)
        if stripped != original:
            backup = original
            with open(PUBSPEC, 'w', encoding='utf-8', newline='') as f:
                f.write(stripped)
            print('>>> pubspec.yaml fonts 段已临时移除（Web 构建）')

        rc = run(['pub', 'get'])
        if rc != 0:
            print('flutter pub get failed (rc=%d)' % rc)
            return rc
        rc = run(['build', 'web', '--release', '--no-tree-shake-icons'])
        print('flutter build web rc=%d' % rc)
        return rc
    finally:
        if backup is not None:
            with open(PUBSPEC, 'w', encoding='utf-8', newline='') as f:
                f.write(backup)
            print('>>> pubspec.yaml 已恢复（fonts 段）')


if __name__ == '__main__':
    sys.exit(main())
