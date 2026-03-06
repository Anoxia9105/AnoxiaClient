import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../model/TranscriptionSegment.dart';
import '../provider/TranscriptionNotifier.dart';

/// 转录字幕Widget - 显示实时转录
class TranscriptionWidget extends ConsumerWidget {
  /// 字幕位置 - top 或 bottom
  final String position;

  /// 是否显示发言者名称
  final bool showSpeakerName;

  /// 是否显示时间戳
  final bool showTimestamp;

  const TranscriptionWidget({
    super.key,
    this.position = 'bottom',
    this.showSpeakerName = true,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcriptionState = ref.watch(transcriptionStateProvider);

    if (!transcriptionState.isEnabled) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      reverse: true,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示以前的转录分段
            ..._buildTranscriptionSegments(context, transcriptionState),

            // 显示临时转录文本
            if (transcriptionState.currentInterimText?.isNotEmpty ?? false)
              _buildInterimText(context, transcriptionState),
          ],
        ),
      ),
    );
  }

  /// 构建转录分段列表
  List<Widget> _buildTranscriptionSegments(
    BuildContext context,
    TranscriptionState state,
  ) {
    return state.segments
        .map((segment) => _buildSegment(context, segment, false))
        .toList();
  }

  /// 构建单个分段
  Widget _buildSegment(
    BuildContext context,
    TranscriptionSegment segment,
    bool isInterim,
  ) {
    final theme = Theme.of(context);
    final textColor = isInterim ? Colors.grey : Colors.white;
    final backgroundColor =
        isInterim ? Colors.black45 : Colors.black54;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 发言者信息
          if (showSpeakerName)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    segment.speakerName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showTimestamp)
                    Text(
                      _formatTime(segment.startTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                ],
              ),
            ),

          // 转录文本
          Text(
            segment.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontStyle: isInterim ? FontStyle.italic : FontStyle.normal,
            ),
          ),

          // 置信度指示器（如果置信度低于0.8）
          if (segment.confidence < 0.8 && !isInterim)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14.sp,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'call_transcription_confidence'.tr(args: [(segment.confidence * 100).toStringAsFixed(0)]),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建临时转录文本
  Widget _buildInterimText(BuildContext context, TranscriptionState state) {
    return _buildSegment(
      context,
      TranscriptionSegment(
        id: 'interim',
        speakerId: state.currentSpeakerId ?? 'unknown',
        speakerName: 'call_transcription_listening'.tr(),
        text: state.currentInterimText ?? '',
        startTime: 0,
        endTime: 0,
        isFinal: false,
      ),
      true,
    );
  }

  /// 格式化时间
  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 转录面板Widget - 可点击显示/隐藏的转录面板
class TranscriptionPanel extends ConsumerStatefulWidget {
  /// 初始是否显示
  final bool initiallyVisible;

  const TranscriptionPanel({
    super.key,
    this.initiallyVisible = true,
  });

  @override
  ConsumerState<TranscriptionPanel> createState() => _TranscriptionPanelState();
}

class _TranscriptionPanelState extends ConsumerState<TranscriptionPanel> {
  late bool _isVisible;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initiallyVisible;
  }

  @override
  Widget build(BuildContext context) {
    final transcriptionState = ref.watch(transcriptionStateProvider);

    if (!transcriptionState.isEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white12,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'call_transcription_title'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white70,
                      onPressed: () {
                        setState(() => _isVisible = false);
                      },
                      constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                      padding: EdgeInsets.zero,
                      iconSize: 18.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 转录内容
          if (_isVisible)
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transcriptionState.segments.isEmpty)
                      Text(
                        'call_transcription_waiting'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      )
                    else
                      ...transcriptionState.segments
                          .map((segment) => Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${segment.speakerName}: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.blue[300],
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      TextSpan(
                                        text: segment.text,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),

                    // 临时转录文本
                    if (transcriptionState.currentInterimText?.isNotEmpty ??
                        false)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'call_transcription_listening_prefix'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextSpan(
                                text: transcriptionState.currentInterimText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.orange.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
