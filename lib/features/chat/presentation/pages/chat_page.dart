// 聊天主页面，负责桌面端聊天布局：左侧房间列表、中间聊天详情、右侧详情面板。
//
// 在移动端直接显示聊天室列表，桌面端支持三栏布局及响应式右侧面板（内联/叠加模式）。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/app/presentation/widgets/welcome.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/chat_room_detail_panel.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/chat_focus_mode_controller.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 聊天主页面
///
/// 桌面端采用三栏布局：左侧聊天室列表、中间聊天详情、右侧房间详情面板。
/// 右侧面板支持响应式切换：宽屏时内联显示，窄屏时叠加显示。
/// 移动端直接显示聊天室列表。
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

/// 聊天主页面状态
///
/// 监听当前活跃房间和右侧面板显示状态，根据屏幕宽度动态切换布局模式。
class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  Widget build(BuildContext context) {
    // 布局按屏幕宽度（响应式）决定，而不是按“真实移动设备”判断：
    // Web 上的手机浏览器 isRealMobile() 永远为 false，会错误地进入桌面三栏。
    // 平台能力（窗口插件等）用 isRealDesktop/isRealMobile，UI 布局用宽度断点。
    if (DeviceUtil.isMobile(context)) {
      return const ChatRoomList();
    }

    final activeRoomId = ref.watch(activeRoomIdProvider);
    final focusModeEnabled = ref.watch(chatFocusModeProvider);
    final showRightPanel = ref.watch(chatRightPanelVisibleProvider);
    // 与记事本/联系人页面保持一致：平铺模式去掉详情区卡片，
    // 避免自定义（视频）背景下各页面右侧区域透明度不一致。
    final supportsDesktopLayout = DeviceUtil.supportsDesktopLayoutPreference(
      context,
    );
    final layoutStyle = supportsDesktopLayout
        ? resolveDesktopLayoutStyle(
            ref.watch(desktopLayoutProvider),
            availableWidth: MediaQuery.sizeOf(context).width,
          )
        : DesktopLayoutStyle.card;
    final isFlat = layoutStyle == DesktopLayoutStyle.flat;
    final room = activeRoomId != null
        ? ref.watch(currentRoomProvider(activeRoomId))
        : null;

    if (focusModeEnabled && activeRoomId?.isNotEmpty == true) {
      return ChatRoomDetail(
        key: ValueKey('focused-chat-$activeRoomId'),
        roomId: activeRoomId!,
      );
    }

    final isCompactWidth = MediaQuery.of(context).size.width < 1000;
    final canShowRightPanel = showRightPanel && activeRoomId != null;
    final inlineRightPanel = canShowRightPanel && !isCompactWidth;
    final overlayRightPanel = canShowRightPanel && isCompactWidth;

    return Stack(
      children: [
        Row(
          children: [
            SizedBox(
              width: isCompactWidth ? 240.0 : 320.0,
              child: const ChatRoomList(),
            ),
            Expanded(
              child: isFlat
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: room == null
                          ? const Welcome.chat()
                          : ChatRoomDetail(
                              key: ValueKey('chat-$activeRoomId'),
                              roomId: activeRoomId!,
                            ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(RadiusToken.xl),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.18),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(RadiusToken.xl),
                          child: room == null
                              ? const Welcome.chat()
                              : ChatRoomDetail(
                                  key: ValueKey('chat-$activeRoomId'),
                                  roomId: activeRoomId!,
                                ),
                        ),
                      ),
                    ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: inlineRightPanel ? 320.0 : 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: inlineRightPanel
                      ? _buildRightPanel(context, activeRoomId, isFlat)
                      : const SizedBox.shrink(
                          key: ValueKey('right-panel-closed'),
                        ),
                ),
              ),
            ),
          ],
        ),
        if (overlayRightPanel)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeRightPanel,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _buildRightPanel(context, activeRoomId, isFlat),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRightPanel(BuildContext context, String roomId, bool isFlat) {
    if (isFlat) {
      // 平铺模式：与中间详情区一致，不套卡片，直接铺在页面表面
      return Container(
        key: ValueKey('right-panel-$roomId'),
        child: ChatRoomDetailPanel(roomId: roomId, onClose: _closeRightPanel),
      );
    }
    return Container(
      key: ValueKey('right-panel-$roomId'),
      margin: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(-8, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        child: ChatRoomDetailPanel(roomId: roomId, onClose: _closeRightPanel),
      ),
    );
  }

  void _closeRightPanel() {
    ref.read(chatRightPanelVisibleProvider.notifier).state = false;
  }
}
