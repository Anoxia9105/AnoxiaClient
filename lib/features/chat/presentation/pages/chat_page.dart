import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Welcome.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/framework/provider/chat/room/chat_split_view_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_view/split_view.dart';

/// 聊天页面容器
///
/// 根据设备类型提供不同的布局：
/// - 移动端：仅显示房间列表
/// - 桌面端/平板：三栏布局（房间列表+聊天详情+搜索面板）
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static final List<WeightLimit?> _splitLimits = <WeightLimit?>[
    WeightLimit(min: 0.15, max: 0.4),
    null,
  ];

  late final SplitViewController _splitViewController;

  @override
  void initState() {
    super.initState();
    _splitViewController = SplitViewController(
      weights: ref.read(chatSplitViewWeightsProvider),
      limits: _splitLimits,
    );
  }

  @override
  void dispose() {
    _splitViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 移动端简化为单栏
    if (DeviceUtil.isRealMobile()) {
      return const ChatRoomList();
    }

    // 桌面端三栏布局
    final activeRoomId = ref.watch(activeRoomIdProvider);
    final splitWeights = ref.watch(chatSplitViewWeightsProvider);
    _syncSplitWeights(splitWeights);

    final room = activeRoomId != null
        ? ref.watch(currentRoomProvider(activeRoomId))
        : null;

    // 1. 判断是否显示欢迎页
    final showWelcome = room == null;

    return SplitView(
      gripSize: 2,
      gripColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      gripColorActive: Theme.of(context).primaryColor,
      viewMode: SplitViewMode.Horizontal,
      controller: _splitViewController,
      onWeightChanged: (weights) {
        ref
            .read(chatSplitViewWeightsProvider.notifier)
            .updateWeights(weights.toList());
      },
      children: [
        const ChatRoomList(),
        if (showWelcome)
          const Welcome.chat()
        else
          ChatRoomDetail(roomId: activeRoomId!),
      ],
    );
  }

  void _syncSplitWeights(List<double> weights) {
    final current = _splitViewController.weights;
    if (current.length != weights.length) {
      _splitViewController.weights = weights;
      return;
    }

    for (var index = 0; index < weights.length; index++) {
      if ((current[index]! - weights[index]).abs() > 0.0001) {
        _splitViewController.weights = weights;
        return;
      }
    }
  }
}
