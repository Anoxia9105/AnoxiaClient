import 'dart:async';

import 'package:flutter/material.dart';

class MobileCallTimer extends StatefulWidget {
  const MobileCallTimer({
    super.key,
    required this.joinedAt,
    this.style,
    this.placeholder = '--:--',
  });

  final DateTime? joinedAt;
  final TextStyle? style;
  final String placeholder;

  @override
  State<MobileCallTimer> createState() => _MobileCallTimerState();
}

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
          const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}
