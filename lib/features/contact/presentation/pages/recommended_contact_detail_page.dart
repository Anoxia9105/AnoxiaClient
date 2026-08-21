import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/recommended_contact_detail_content.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 按端型展示「名片公开资料与好友请求」：
///
/// - 真实桌面端 / Web PC 宽屏：统一式样弹窗（左侧返回按钮 + 标题，支持 ESC 关闭）
/// - 真实移动端 / Web SP 窄屏：压栈跳转 [RecommendedContactDetailPage]
Future<void> showRecommendedContactDetail(
  BuildContext context,
  CardPayload card,
) {
  return presentAdaptivePage<void>(
    context,
    builder: (_) => RecommendedContactDetailPage(card: card),
  );
}

/// 从名片进入的公开资料与好友请求页面（移动端 / Web SP 为路由页，
/// 桌面端 / Web PC 由 [showRecommendedContactDetail] 以弹窗承载）
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
