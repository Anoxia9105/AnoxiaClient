import 'dart:async';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI 功能开关（AnoxiaAdmin「AI 服务设置」人工开关 + 上游探测叠加）
///
/// - [chatEnabled]/[noteEnabled]：管理端人工开关。
/// - [available]：上游 AI 是否可用（密钥缺失/上游异常熔断时为 false，
///   由 `GET /chat/ai/health` 下发；失败时 fail-open 为 true，避免首屏误隐藏）。
/// - 入口展示必须用 [chatAvailable]/[noteAvailable]（开关与探测同时满足），
///   直接读 [chatEnabled]/[noteEnabled] 会漏掉上游故障时的动态隐藏。
class AiFeatureFlags {
  const AiFeatureFlags({
    required this.chatEnabled,
    required this.noteEnabled,
    required this.available,
    this.reason,
  });

  final bool chatEnabled;
  final bool noteEnabled;

  /// 上游 AI 可用性（false 时聊天 AI 与记事本 AI 入口全部隐藏）
  final bool available;

  /// 服务端 reason 机器码（ok/not_probed/disabled/no_key/no_model/
  /// upstream_error/unknown），仅排障用，不直接展示
  final String? reason;

  /// 聊天 AI 入口是否展示
  bool get chatAvailable => chatEnabled && available;

  /// 记事本 AI 入口是否展示
  bool get noteAvailable => noteEnabled && available;

  bool get anyEnabled => chatAvailable || noteAvailable;

  AiFeatureFlags copyWith({
    bool? chatEnabled,
    bool? noteEnabled,
    bool? available,
    String? reason,
  }) {
    return AiFeatureFlags(
      chatEnabled: chatEnabled ?? this.chatEnabled,
      noteEnabled: noteEnabled ?? this.noteEnabled,
      available: available ?? this.available,
      reason: reason ?? this.reason,
    );
  }
}

/// 上报一次 AI 调用结果（成功/失败），驱动本地熔断与恢复。
///
/// 所有 AI 流式入口（聊天/记事本/智能回复）在终态处调用：
/// 连续失败达阈值即本地隐藏入口，成功则解除并向服务端复核。
/// 有 `WidgetRef` 时用 `ref.read`，普通 `State` 用
/// `ProviderScope.containerOf(context).read(...)`。
void reportAiHealth(WidgetRef ref, bool success) {
  final notifier = ref.read(aiFeatureFlagsProvider.notifier);
  if (success) {
    notifier.reportSuccess();
  } else {
    notifier.reportFailure();
  }
}

/// 从 `data` 信封/裸 map 中解析开关（health 与 models 接口通用，可单测）
AiFeatureFlags aiFeatureFlagsFromMap(Map? map) {
  final chatEnabled = map?['chatEnabled'] as bool? ?? true;
  final noteEnabled = map?['noteEnabled'] as bool? ?? true;
  final available = map?['available'] as bool? ?? true;
  final reason = map?['reason'] as String? ?? map?['healthReason'] as String?;
  return AiFeatureFlags(
    chatEnabled: chatEnabled,
    noteEnabled: noteEnabled,
    available: available,
    reason: reason,
  );
}

/// 拉取服务端开关 + 上游健康，失败时默认全部可用（避免首屏闪烁误隐藏）
class AiFeatureFlagsNotifier extends AsyncNotifier<AiFeatureFlags> {
  Timer? _timer;
  Timer? _cooldown;

  /// 连续失败计数（成功一次即清零，容忍单次抖动）
  int _failures = 0;

  @override
  Future<AiFeatureFlags> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _cooldown?.cancel();
    });

    // 账号切换时重新拉取
    ref.listen(authControllerProvider, (prev, next) {
      final prevId = prev?.value?.userId;
      final nextId = next.value?.userId;
      if (prevId != nextId) {
        _failures = 0;
        refresh();
      }
    });

    final flags = await _fetch();
    // 每 2 分钟静默刷新一次：管理端关闭或上游熔断后客户端较快隐藏入口，
    // 恢复后也能较快重新展示
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      refresh();
    });
    return flags;
  }

  Map? _dataOf(Object? data) {
    if (data is Map) {
      if (data['data'] is Map) return data['data'] as Map;
      return data;
    }
    return null;
  }

  Future<AiFeatureFlags> _fetch() async {
    try {
      // 优先探测接口（含上游可用性）；老服务端 404 时回退到 models 接口
      try {
        final resp = await DioClient().get(API.chatAiHealth);
        return aiFeatureFlagsFromMap(_dataOf(resp.data));
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        final resp = await DioClient().get(API.chatAiModels);
        return aiFeatureFlagsFromMap(_dataOf(resp.data));
      }
    } catch (_) {
      // 未登录/网络异常时不隐藏，等待下一次刷新
      return const AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: true,
      );
    }
  }

  /// AI 调用失败时上报；连续失败达阈值立即本地隐藏入口，
  /// 并在冷却后向服务端复核（上游恢复可自动重新展示）。
  void reportFailure() {
    _failures++;
    if (_failures < 2) return;
    final current = state.value;
    if (current != null && current.available) {
      state = AsyncData(current.copyWith(available: false, reason: 'local'));
    }
    _cooldown?.cancel();
    _cooldown = Timer(const Duration(seconds: 60), () {
      _failures = 0;
      refresh();
    });
  }

  /// AI 调用成功时上报；解除本地熔断（若正隐藏则立即向服务端复核）。
  void reportSuccess() {
    _failures = 0;
    _cooldown?.cancel();
    final current = state.value;
    if (current != null && !current.available) {
      refresh();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final aiFeatureFlagsProvider =
    AsyncNotifierProvider<AiFeatureFlagsNotifier, AiFeatureFlags>(
        () => AiFeatureFlagsNotifier());
