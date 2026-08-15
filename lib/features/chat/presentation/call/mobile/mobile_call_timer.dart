// 移动端通话计时器组件，实时显示通话已持续时间。
//
// 在通话界面中显示格式化的通话时长（MM:SS 或 HH:MM:SS），每秒更新一次。
import 'dart:async';

import 'package:flutter/material.dart';

/// 移动端通话计时器
///
/// 通过 [joinedAt] 参数传入加入通话时间，自动计算并每秒刷新显示已通话时长。
/// 支持自定义文本样式和未加入时显示的占位符。
class MobileCallTimer extends StatefulWidget {
  const MobileCallTimer({
    super.key,
    required this.joinedAt,
    this.style,
    this.placeholder = '--:--',
  });

  /// 加入通话的时间，为 null 时显示占位符
  final DateTime? joinedAt;

  /// 自定义文本样式
  final TextStyle? style;

  /// 未加入通话时显示的占位符文本，默认为 "--:--"
  final String placeholder;

  @override
  State<MobileCallTimer> createState() => _MobileCallTimerState();
}

/// 移动端通话计时器状态
///
/// 每秒更新一次已通话时长，当 [joinedAt] 变化时重新开始计时。
class _MobileCallTimerState extends State<MobileCallTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant MobileCallTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joinedAt != widget.joinedAt) {
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    final joinedAt = widget.joinedAt;
    if (joinedAt == null) {
      _elapsed = Duration.zero;
      return;
    }
    _elapsed = DateTime.now().difference(joinedAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(joinedAt));
    });
  }

  String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final suffix =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return hours > 0 ? '${hours.toString().padLeft(2, '0')}:$suffix' : suffix;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.joinedAt == null ? widget.placeholder : _format(_elapsed),
      style:
          widget.style ??
          TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}
