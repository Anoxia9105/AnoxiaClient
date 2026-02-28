import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/TranscriptionSegment.dart';

/// 转录状态
class TranscriptionState {
  /// 转录分段列表
  final List<TranscriptionSegment> segments;

  /// 当前活跃的临时转录文本（未final的）
  final String? currentInterimText;

  /// 当前说话者ID
  final String? currentSpeakerId;

  /// 是否启用转录
  final bool isEnabled;

  /// 错误信息
  final String? error;

  const TranscriptionState({
    this.segments = const [],
    this.currentInterimText,
    this.currentSpeakerId,
    this.isEnabled = true,
    this.error,
  });

  /// 复制方法
  TranscriptionState copyWith({
    List<TranscriptionSegment>? segments,
    String? currentInterimText,
    String? currentSpeakerId,
    bool? isEnabled,
    String? error,
  }) {
    return TranscriptionState(
      segments: segments ?? this.segments,
      currentInterimText: currentInterimText ?? this.currentInterimText,
      currentSpeakerId: currentSpeakerId ?? this.currentSpeakerId,
      isEnabled: isEnabled ?? this.isEnabled,
      error: error ?? this.error,
    );
  }
}

/// 转录管理器 - 管理实时转录数据
class TranscriptionManager {
  final List<TranscriptionSegment> segments = [];
  String? currentInterimText;
  String? currentSpeakerId;
  bool isEnabled = true;

  /// 添加转录分段
  void addSegment(TranscriptionSegment segment) {
    segments.add(segment);
    if (segment.isFinal) {
      currentInterimText = null;
    } else {
      currentInterimText = segment.text;
    }
    currentSpeakerId = segment.speakerId;
  }

  /// 更新临时转录文本
  void updateInterimText(String text) {
    currentInterimText = text;
  }

  /// 清空临时转录
  void clearInterimText() {
    currentInterimText = null;
  }

  /// 启用/禁用转录
  void setTranscriptionEnabled(bool enabled) {
    isEnabled = enabled;
  }

  /// 清空所有转录
  void clearAll() {
    segments.clear();
    currentInterimText = null;
    currentSpeakerId = null;
  }
}

/// 转录管理器提供者
final transcriptionManagerProvider = Provider<TranscriptionManager>((ref) {
  return TranscriptionManager();
});

/// 转录状态提供者
final transcriptionStateProvider = Provider<TranscriptionState>((ref) {
  final manager = ref.watch(transcriptionManagerProvider);
  return TranscriptionState(
    segments: manager.segments,
    currentInterimText: manager.currentInterimText,
    currentSpeakerId: manager.currentSpeakerId,
    isEnabled: manager.isEnabled,
  );
});
