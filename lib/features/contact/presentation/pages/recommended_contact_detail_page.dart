import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/recommended_contact_detail_content.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 按端型展示「名片公开资料与好友请求」：
///
/// - 真实桌面端 / Web PC 宽屏：居中弹窗展示
/// - 真实移动端 / Web SP 窄屏：压栈跳转 [RecommendedContactDetailPage]
Future<void> showRecommendedContactDetail(
  BuildContext context,
  CardPayload card,
) async {
  if (DeviceUtil.isDesktop(context)) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .45),
      builder: (_) => _RecommendedContactDetailDialog(card: card),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RecommendedContactDetailPage(card: card),
    ),
  );
}

/// 从名片进入的公开资料与好友请求页面（移动端 / Web SP）
class RecommendedContactDetailPage extends StatelessWidget {
  final CardPayload card;

  const RecommendedContactDetailPage({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // 显式指定主题背景色：全局 Scaffold 背景为透明（供自定义背景层使用），
      // 缺省时本页会透出底层内容且不随主题变化
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text('contact_card_detail_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: RecommendedContactDetailContent(card: card),
          ),
        ),
      ),
    );
  }
}

/// 桌面端 / Web PC 的名片详情弹窗
class _RecommendedContactDetailDialog extends StatelessWidget {
  final CardPayload card;

  const _RecommendedContactDetailDialog({required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: screenHeight * .85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏：标题 + 关闭按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'contact_card_detail_title'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'cancel'.tr(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: .5),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RecommendedContactDetailContent(card: card),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
