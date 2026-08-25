import 'dart:async';

import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI 功能开关（由 AnoxiaAdmin「AI 服务设置」控制）
class AiFeatureFlags {
  const AiFeatureFlags({
    required this.chatEnabled,
    required this.noteEnabled,
  });

  final bool chatEnabled;
  final bool noteEnabled;

  bool get anyEnabled => chatEnabled || noteEnabled;
}

/// 拉取服务端开关，失败时默认全部开启（避免首屏闪烁误隐藏）
class AiFeatureFlagsNotifier extends AsyncNotifier<AiFeatureFlags> {
  Timer? _timer;

  @override
  Future<AiFeatureFlags> build() async {
    ref.onDispose(() => _timer?.cancel());

    // 账号切换时重新拉取
    ref.listen(authControllerProvider, (prev, next) {
      final prevId = prev?.value?.userId;
      final nextId = next.value?.userId;
      if (prevId != nextId) {
        refresh();
      }
    });

    final flags = await _fetch();
    // 每 5 分钟静默刷新一次，保证管理端关闭后客户端较快隐藏入口
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      refresh();
    });
    return flags;
  }

  Future<AiFeatureFlags> _fetch() async {
    try {
      final resp = await DioClient().get('/chat/ai/models');
      final data = resp.data;
      Map? map;
      if (data is Map) {
        if (data['data'] is Map) {
          map = data['data'] as Map;
        } else {
          map = data;
        }
      }
      final chatEnabled = map?['chatEnabled'] as bool? ?? true;
      final noteEnabled = map?['noteEnabled'] as bool? ?? true;
      return AiFeatureFlags(chatEnabled: chatEnabled, noteEnabled: noteEnabled);
    } catch (_) {
      // 未登录/网络异常时不隐藏，等待登录后下一次刷新
      return const AiFeatureFlags(chatEnabled: true, noteEnabled: true);
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
