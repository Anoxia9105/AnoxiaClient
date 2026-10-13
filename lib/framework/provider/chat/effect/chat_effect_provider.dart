import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/token_provider.dart';
import 'chat_effect_dispatcher.dart';

part 'chat_effect_provider.g.dart';

@Riverpod(keepAlive: true)
ChatEffectDispatcher chatEffectDispatcher(Ref ref) {
  // 会话变化立即释放旧事件、别名和冷却，不跨账号共享视觉状态。
  ref.watch(tokenCacheProvider);
  final dispatcher = ChatEffectDispatcher();
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
}
