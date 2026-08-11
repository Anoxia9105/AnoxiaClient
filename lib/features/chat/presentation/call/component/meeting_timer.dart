import 'dart:async';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 会议计时器组件
///
/// 显示当前通话已持续的时间，从加入房间开始计时
class MeetingTimer extends StatefulWidget {
  /// 加入房间的时间
  final DateTime? joinedAt;

  const MeetingTimer({super.key, required this.joinedAt});

  @override
  State<MeetingTimer> createState() => _MeetingTimerState();
}

class _MeetingTimerState extends State<MeetingTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.joinedAt != null) {
      _elapsed = DateTime.now().difference(widget.joinedAt!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(widget.joinedAt!);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeetingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joinedAt != widget.joinedAt) {
      _timer?.cancel();
      if (widget.joinedAt != null) {
        _elapsed = DateTime.now().difference(widget.joinedAt!);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _elapsed = DateTime.now().difference(widget.joinedAt!);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 格式化时长显示
  ///
  /// 超过1小时显示 HH:MM:SS，否则显示 MM:SS
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.joinedAt == null) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedTime01, size: 20),
          Text('--:--', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(_elapsed), style: const TextStyle(fontSize: 12)),
        Text('call_elapsed'.tr(), style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}