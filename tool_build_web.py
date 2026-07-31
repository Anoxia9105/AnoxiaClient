import os
import re
import subprocess
import sys

# 允许通过环境变量覆盖，避免硬编码路径在换电脑 / CI 时失效。
PKG_ROOT = os.environ.get('ANOXIA_WEB_PKG_ROOT', r'D:\GIT\anoxia\AnoxiaClient')
PUBSPEC = os.path.join(PKG_ROOT, 'pubspec.yaml')
BAK = PUBSPEC + '.bak'

# Web-incompatible plugins that are only referenced via lib/platform/shims/*
# (their native package is never imported in the web compilation graph),
# plus sqlite3_flutter_libs which is native-only.
STRIP = [
    'tray_manager',
    'window_manager',
    'desktop_multi_window',
    'hotkey_manager',
    'flutter_background',
    'pip',
    'jpush_flutter',
    'firebase_messaging',
    'flutter_local_notifications',
    'app_badge_plus',
    'mobile_scanner',
    'image_gallery_saver_plus',
    'image_cropper',
    'sqlite3_flutter_libs',
]

names = set(STRIP)


def strip_deps(text):
    lines = text.split('\n')
    res = []
    i = 0
    in_deps = False
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped == 'dependencies:':
            in_deps = True
            res.append(line)
            i += 1
            continue
        if stripped in ('dev_dependencies:', 'dependency_overrides:', 'flutter:'):
            in_deps = False
            res.append(line)
            i += 1
            continue
        if in_deps:
            m = re.match(r'^  ([A-Za-z0-9_]+):', line)
            if m and m.group(1) in names:
                i += 1
                while i < len(lines):
                    nxt = lines[i]
                    if nxt.strip() == '':
                        i += 1
                        continue
                    if re.match(r'^  [A-Za-z0-9_]+:', nxt) or re.match(
                        r'^[A-Za-z0-9_]+:', nxt
                    ):
                        break
                    i += 1
                continue
        res.append(line)
        i += 1
    return '\n'.join(res)


FLUTTER_BIN = os.environ.get(
    'FLUTTER_BIN',
    r'D:/SDK/flutter/flutter_windows_3.44.0-stable/flutter/bin/flutter.bat',
)


def run(args):
    # args 为 flutter 子命令列表，例如 ['pub', 'get']。前置 flutter SDK 路径。
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
    with open(PUBSPEC, 'r', encoding='utf-8') as f:
        original = f.read()
    with open(BAK, 'w', encoding='utf-8') as f:
        f.write(original)

    stripped = strip_deps(original)
    removed = [n for n in STRIP if ('  %s:' % n) in original]
    print('Stripping from pubspec: %s' % ', '.join(removed))
    with open(PUBSPEC, 'w', encoding='utf-8') as f:
        f.write(stripped)

    try:
        rc = run(['pub', 'get'])
        if rc != 0:
            print('flutter pub get failed (rc=%d)' % rc)
            return rc
        rc = run(['build', 'web', '--release'])
        print('flutter build web rc=%d' % rc)
        return rc
    finally:
        # 恢复完整 pubspec 后，必须重新 pub get，否则 .dart_tool/package_config.json
        # 与插件注册文件仍停留在“删减依赖”状态，后续 Android/Windows 原生构建
        # 会出现找不到包或插件注册错乱的问题。
        with open(PUBSPEC, 'w', encoding='utf-8') as f:
            f.write(original)
        print('pubspec.yaml restored, re-running flutter pub get to restore native env')
        rc2 = run(['pub', 'get'])
        # 若 Web 构建成功但恢复原生依赖失败，必须让脚本以非 0 退出，否则 CI 会
        # 误判构建成功、把处于损坏状态的原生环境带进后续流水线。
        if rc2 != 0:
            print('ERROR: flutter pub get (restore native env) failed (rc=%d)' % rc2)
            sys.exit(rc2)


if __name__ == '__main__':
    sys.exit(main())
