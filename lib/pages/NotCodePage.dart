import 'package:anoxia/framework/extensions/TaskbarBadgeUpdater.dart';
import 'package:flutter/material.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

class NotCodePage extends StatefulWidget {
  const NotCodePage({super.key});

  @override
  State<NotCodePage> createState() => _NotCodePageState();
}

class _NotCodePageState extends State<NotCodePage> {
  int count = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.date_range, size: 64, color: Colors.blueAccent),
            // Text("暂无数据", style: TextStyle(fontSize: 16)),
            FilledButton(
              onPressed: () async {
                // WindowsTaskbar.setProgress(69, 100);
                WindowsTaskbar.setProgressMode(
                  TaskbarProgressMode.indeterminate,
                );
              },
              child: Text("设置进度"),
            ),

            FilledButton(
              onPressed: () async {
                WindowsTaskbar.setFlashTaskbarAppIcon(
                  mode: TaskbarFlashMode.all | TaskbarFlashMode.timernofg,
                  timeout: const Duration(milliseconds: 500),
                );
              },
              child: Text("刷入Windows任务栏应用图标"),
            ),
            FilledButton(
              onPressed: () async {
                WindowsTaskbar.resetFlashTaskbarAppIcon();
              },
              child: Text("停止闪烁Windows任务栏应用图标"),
            ),

            FilledButton(
              onPressed: () async {
                WindowsTaskbar.resetOverlayIcon();
              },
              child: Text("移除覆盖图标（徽章）"),
            ),

            FilledButton(
              onPressed: () async {
                TaskbarBadgeUpdater.updateBadge(count++);
              },
              child: Text("+++"),
            ),
          ],
        ),
      ),
    );
  }
}
