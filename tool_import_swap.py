import os

ROOT = r'D:\GIT\anoxia\AnoxiaClient\lib'

mapping = {
    'package:window_manager/window_manager.dart': 'package:anoxia/platform/shims/window_manager_shim.dart',
    'package:tray_manager/tray_manager.dart': 'package:anoxia/platform/shims/tray_manager_shim.dart',
    'package:desktop_multi_window/desktop_multi_window.dart': 'package:anoxia/platform/shims/desktop_multi_window_shim.dart',
    'package:hotkey_manager/hotkey_manager.dart': 'package:anoxia/platform/shims/hotkey_manager_shim.dart',
    'package:mobile_scanner/mobile_scanner.dart': 'package:anoxia/platform/shims/mobile_scanner_shim.dart',
    'package:image_cropper/image_cropper.dart': 'package:anoxia/platform/shims/image_cropper_shim.dart',
    'package:image_gallery_saver_plus/image_gallery_saver_plus.dart': 'package:anoxia/platform/shims/image_gallery_saver_plus_shim.dart',
    'package:flutter_background/flutter_background.dart': 'package:anoxia/platform/shims/flutter_background_shim.dart',
    'package:pip/pip.dart': 'package:anoxia/platform/shims/pip_shim.dart',
}

exclude_dirs = ['platform/shims']
exclude_files = {
    'framework/core/notification_helper.dart',
    'framework/core/notification_helper_io.dart',
    'framework/core/notification_helper_web.dart',
    'framework/local_cache/database.dart',
    'framework/local_cache/database_native.dart',
    'framework/local_cache/database_web.dart',
    'framework/core/push_manager_io.dart',
}

changed = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    rel_dir = os.path.relpath(dirpath, ROOT).replace('\\', '/')
    if any(rel_dir == d or rel_dir.startswith(d + '/') for d in exclude_dirs):
        continue
    for fn in filenames:
        if not fn.endswith('.dart'):
            continue
        rel = (rel_dir + '/' + fn) if rel_dir != '.' else fn
        if rel in exclude_files:
            continue
        path = os.path.join(dirpath, fn)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = content
        for orig, repl in mapping.items():
            new_content = new_content.replace(orig, repl)
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            changed.append(rel)

print('Changed %d files:' % len(changed))
for c in changed:
    print('  ' + c)
