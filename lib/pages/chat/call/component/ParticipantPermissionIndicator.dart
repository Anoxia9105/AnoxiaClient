import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';

/// 参与者权限指示器
/// 显示参与者是否有发布权限限制
class ParticipantPermissionIndicator extends StatelessWidget {
  final Participant participant;

  const ParticipantPermissionIndicator({
    super.key,
    required this.participant,
  });

  bool _hasPermissionRestrictions() {
    // 检查参与者是否有任何权限限制
    // 这是一个占位符实现 - 在实际应用中，
    // 您需要根据 SDK 提供的权限 API 来检查
    return false; // 默认无限制
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissionRestrictions()) {
      return SizedBox.shrink();
    }

    return Tooltip(
      message: 'call_permission_restricted_tooltip'.tr(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.admin_panel_settings,
          size: 14,
          color: Colors.orange,
        ),
      ),
    );
  }
}
