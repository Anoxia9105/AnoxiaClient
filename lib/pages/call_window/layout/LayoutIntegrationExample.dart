/// Phase 3.3 高级布局集成示例
/// 
/// 这个文件展示如何在 CallRoomPage 中集成 AdvancedLayoutSelector
/// 复制相关代码到你的项目中

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/pages/call_window/layout/AdvancedLayoutSelector.dart';

/// 示例: 在 CallRoomPage 中使用 AdvancedLayoutSelector
class CallRoomPageAdvancedLayoutExample extends ConsumerStatefulWidget {
  final String token;

  const CallRoomPageAdvancedLayoutExample({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<CallRoomPageAdvancedLayoutExample> createState() =>
      _CallRoomPageStateExample();
}

class _CallRoomPageStateExample
    extends ConsumerState<CallRoomPageAdvancedLayoutExample> {
  @override
  Widget build(BuildContext context) {
    // 从你的 room controller 获取房间状态和参与者列表
    // final roomAsync = ref.watch(roomControllerProvider(widget.token));

    // 这是一个示例，使用模拟数据
    return Scaffold(
      body: Stack(
        children: [
          // 高级布局选择器 - 替换原有的 LayoutRoomWidget
          Expanded(
            child: AdvancedLayoutSelector(
              token: widget.token,
              participants: [
                // 这里应该来自 roomState.room.localParticipant 和 roomState.remoteParticipants
                // 参考实际实现的数据来源
              ],
              focusedParticipant: null,
              onParticipantTap: (participant) {
                // 处理参与者点击事件
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: ${participant.name}'),
                  ),
                );
              },
              onUnfocus: () {
                // 处理取消焦点事件
                print('Layout unfocused');
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 完整的集成示例
/// 将以下代码段复制到你的 CallRoomPage 中:
/// 
/// ```dart
/// import 'package:anoxia/pages/call_window/layout/AdvancedLayoutSelector.dart';
/// 
/// class CallRoomPage extends ConsumerStatefulWidget {
///   final String token;
///   const CallRoomPage({super.key, required this.token});
///   
///   @override
///   ConsumerState<CallRoomPage> createState() => _CallRoomPageState();
/// }
/// 
/// class _CallRoomPageState extends ConsumerState<CallRoomPage> {
///   bool _showChat = false;
///   
///   @override
///   Widget build(BuildContext context) {
///     final roomAsync = ref.watch(roomControllerProvider(widget.token));
///     
///     return Scaffold(
///       body: roomAsync.when(
///         loading: () => Center(child: CircularProgressIndicator()),
///         error: (err, stack) => Center(child: Text('Error: $err')),
///         data: (roomState) {
///           // 收集所有参与者
///           final participants = <Participant>[
///             if (roomState.room.localParticipant != null)
///               roomState.room.localParticipant!,
///             ...roomState.remoteParticipants,
///           ];
///           
///           // 检查屏幕共享
///           final screenSharer = participants
///               .where((p) => p.videoTrackPublications.any((pub) => pub.isScreenShare))
///               .firstOrNull;
///           
///           return Stack(
///             children: [
///               Row(
///                 children: [
///                   Expanded(
///                     child: Column(
///                       children: [
///                         // 工具栏
///                         CommandBar(
///                           state: roomState,
///                           onToggleChat: () => setState(() => _showChat = !_showChat),
///                           showChat: _showChat,
///                         ),
///                         
///                         // 屏幕共享状态栏
///                         ScreenShareStatusBar(room: roomState.room),
///                         
///                         // 高级布局选择器 - 核心改变
///                         Expanded(
///                           child: participants.isEmpty
///                               ? Center(child: Text('No participants'))
///                               : screenSharer == null
///                                   ? AdvancedLayoutSelector(  // ← 用这个替换 LayoutRoomWidget
///                                       token: widget.token,
///                                       participants: participants,
///                                       onParticipantTap: (participant) {
///                                         // 可选: 处理参与者点击
///                                       },
///                                       onUnfocus: () {
///                                         // 可选: 处理取消焦点
///                                       },
///                                     )
///                                   : LayoutRoomScreenWidget(  // 屏幕共享时仍使用原有布局
///                                       screenParticipant: screenSharer,
///                                       otherParticipants: participants
///                                           .where((p) => p.sid != screenSharer.sid)
///                                           .toList(),
///                                     ),
///                         ),
///                       ],
///                     ),
///                   ),
///                   
///                   // 聊天面板 (如果启用)
///                   if (_showChat)
///                     SizedBox(
///                       width: 300,
///                       child: LiveKitChatWidget(token: widget.token),
///                     ),
///                 ],
///               ),
///             ],
///           );
///         },
///       ),
///     );
///   }
/// }
/// ```

// ============================================================================
// 布局模式选择算法示例
// ============================================================================

/// 如何根据不同条件选择布局
class LayoutSelectionExample {
  /// 根据参与者数量选择布局
  static String selectByParticipantCount(int count) {
    if (count <= 1) {
      return 'Focus (1对1通话)';
    } else if (count <= 3) {
      return 'Carousel (小组讨论)';
    } else {
      return 'Grid (多人会议)';
    }
  }

  /// 根据场景选择布局
  static String selectByScenario(String scenario) {
    switch (scenario) {
      case 'one-on-one':
        return 'Focus';
      case 'team-meeting':
        return 'Grid';
      case 'presentation':
        return 'Carousel';
      case 'classroom':
        return 'Grid';
      case 'interview':
        return 'Carousel';
      default:
        return 'Grid';
    }
  }

  /// 根据网络状况选择布局
  static String selectByNetworkQuality(double bandwidth) {
    // 高质量: 选择 Grid (需要更多编码/解码)
    // 中等: 选择 Carousel (平衡方案)
    // 低质量: 选择 Focus (最少视频流)

    if (bandwidth > 5.0) {
      return 'Grid (高带宽)';
    } else if (bandwidth > 2.0) {
      return 'Carousel (中等带宽)';
    } else {
      return 'Focus (低带宽)';
    }
  }
}

// ============================================================================
// 高级: 自定义布局选择逻辑
// ============================================================================

/// 扩展 LayoutManager 添加自定义选择逻辑
class CustomLayoutManager {
  /// 根据多个因素智能选择布局
  String intelligentLayoutSelection({
    required int participantCount,
    required double networkQuality,
    required bool isPresenting,
  }) {
    // 如果有演讲者，使用 Carousel
    if (isPresenting) {
      return 'Carousel';
    }

    // 如果参与者很多但网络差，使用 Focus
    if (participantCount > 5 && networkQuality < 2.0) {
      return 'Focus';
    }

    // 根据参与者数量选择
    if (participantCount <= 2) {
      return 'Focus';
    } else if (participantCount <= 4) {
      return 'Carousel';
    } else {
      return 'Grid';
    }
  }

  /// 生成布局建议文本
  String getLayoutSuggestion({
    required int participantCount,
    required double networkQuality,
  }) {
    String suggestion = 'Layout Suggestions:\n';
    suggestion += '- Participants: $participantCount\n';
    suggestion += '- Network Quality: ${networkQuality.toStringAsFixed(2)} Mbps\n';

    if (participantCount <= 2) {
      suggestion += '✓ Recommended: Focus Layout\n';
      suggestion += '  Reason: Maximize video quality for 1-on-1\n';
    } else if (participantCount <= 5) {
      suggestion += '✓ Recommended: Carousel Layout\n';
      suggestion += '  Reason: Balance between focus and overview\n';
    } else {
      suggestion += '✓ Recommended: Grid Layout\n';
      suggestion += '  Reason: Show all participants equally\n';
    }

    return suggestion;
  }
}
