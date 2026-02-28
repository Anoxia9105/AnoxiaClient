import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/pages/call_window/provider/LayoutProvider.dart';
import 'package:anoxia/pages/call_window/room_layout/LiveKitGridLayout.dart' hide LayoutMode;
import 'package:anoxia/pages/call_window/room_layout/LiveKitCarouselLayout.dart';
import 'package:anoxia/pages/call_window/room_layout/LiveKitFocusLayout.dart';

/// 高级布局选择器 - 根据参与者数量自动或手动切换布局
/// 
/// 特点:
/// - 网格布局: 3-16个参与者的多人会议
/// - 轮播布局: 1-8个参与者的演讲/直播
/// - 焦点布局: 1对1通话
class AdvancedLayoutSelector extends ConsumerWidget {
  final String token;
  final List<Participant> participants;
  final Participant? focusedParticipant;
  final void Function(Participant)? onParticipantTap;
  final VoidCallback? onUnfocus;

  const AdvancedLayoutSelector({
    super.key,
    required this.token,
    required this.participants,
    this.focusedParticipant,
    this.onParticipantTap,
    this.onUnfocus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutManager = ref.watch(layoutProvider);
    final currentMode = layoutManager.state.mode;
    final focusedSid = layoutManager.state.focusedParticipantSid;

    // 根据参与者数量自动调整布局
    WidgetsBinding.instance.addPostFrameCallback((_) {
      layoutManager.autoSelectLayout(participants.length);
    });

    // 获取焦点参与者
    Participant? focusedPerson;
    if (focusedSid != null && participants.isNotEmpty) {
      try {
        focusedPerson = participants.firstWhere((p) => p.sid == focusedSid);
      } catch (e) {
        focusedPerson = null;
      }
    }

    return Stack(
      children: [
        // 主布局
        _buildLayout(currentMode, focusedPerson, layoutManager),

        // 右上角布局切换按钮
        Positioned(
          top: 8,
          right: 8,
          child: _buildLayoutSwitcher(context, currentMode, layoutManager),
        ),
      ],
    );
  }

  /// 根据布局模式构建相应的 Widget
  Widget _buildLayout(
    LayoutMode mode,
    Participant? focusedPerson,
    LayoutManager layoutManager,
  ) {
    if (mode == LayoutMode.grid) {
      return LiveKitGridLayout(token: token);
    } else if (mode == LayoutMode.carousel) {
      return LiveKitCarouselLayout(
        token: token,
        focusedParticipant: focusedPerson ?? participants.firstOrNull,
        onParticipantTap: (participant) {
          layoutManager.setFocusedParticipant(participant.sid);
          onParticipantTap?.call(participant);
        },
      );
    } else if (mode == LayoutMode.focus) {
      if (participants.isEmpty) {
        return Center(
          child: Text('call_waiting_to_join'.tr()),
        );
      }
      return LiveKitFocusLayout(
        token: token,
        focusedParticipant: focusedPerson ?? participants.first,
        onUnfocus: () {
          layoutManager.setFocusedParticipant(null);
          onUnfocus?.call();
        },
      );
    } else {
      return LiveKitGridLayout(token: token);
    }
  }

  /// 构建布局切换器按钮
  Widget _buildLayoutSwitcher(
    BuildContext context,
    LayoutMode currentMode,
    LayoutManager layoutManager,
  ) {
    return PopupMenuButton<LayoutMode>(
      initialValue: currentMode,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (mode) {
        layoutManager.setLayoutMode(mode);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: LayoutMode.grid,
          child: _buildMenuItemWithDescription(
            icon: Icons.grid_3x3,
            label: 'layout_grid'.tr(),
            description: '多人会议',
            isSelected: currentMode == LayoutMode.grid,
          ),
        ),
        PopupMenuItem(
          value: LayoutMode.carousel,
          child: _buildMenuItemWithDescription(
            icon: Icons.featured_play_list,
            label: 'layout_carousel'.tr(),
            description: '演讲/直播',
            isSelected: currentMode == LayoutMode.carousel,
          ),
        ),
        PopupMenuItem(
          value: LayoutMode.focus,
          child: _buildMenuItemWithDescription(
            icon: Icons.fullscreen,
            label: 'layout_focus'.tr(),
            description: '单人焦点',
            isSelected: currentMode == LayoutMode.focus,
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getLayoutIcon(currentMode),
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              _getLayoutName(currentMode),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建带描述的菜单项
  Widget _buildMenuItemWithDescription({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 获取布局图标
  IconData _getLayoutIcon(LayoutMode mode) {
    if (mode == LayoutMode.grid) {
      return Icons.grid_3x3;
    } else if (mode == LayoutMode.carousel) {
      return Icons.featured_play_list;
    } else {
      return Icons.fullscreen;
    }
  }

  /// 获取布局名称
  String _getLayoutName(LayoutMode mode) {
    if (mode == LayoutMode.grid) {
      return 'Grid';
    } else if (mode == LayoutMode.carousel) {
      return 'Carousel';
    } else {
      return 'Focus';
    }
  }
}
