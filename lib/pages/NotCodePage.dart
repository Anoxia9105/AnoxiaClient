import 'dart:convert';

import 'package:anoxia/framework/extensions/window_controller.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';

import 'RoomPage.dart'; // 确保这里引入了你刚才写的 RoomPage

const _channel = WindowMethodChannel('example_video_player_window');

class NotCodePage extends StatefulWidget {
  const NotCodePage({super.key});

  @override
  State<NotCodePage> createState() => _NotCodePageState();
}

class _NotCodePageState extends State<NotCodePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.date_range, size: 64, color: Colors.blueAccent),
            Text("暂无数据", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
