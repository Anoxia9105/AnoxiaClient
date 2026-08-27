import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 消息类型展示样式（图标 + 主题色）
class FavoriteTypeStyle {
  final List<List<dynamic>> icon;
  final MaterialColor color;

  const FavoriteTypeStyle(this.icon, this.color);
}

const Map<MessageType, FavoriteTypeStyle> favoriteTypeStyles = {
  MessageType.text: FavoriteTypeStyle(HugeIcons.strokeRoundedQuoteDown, Colors.blue),
  MessageType.richText: FavoriteTypeStyle(
    HugeIcons.strokeRoundedFile02,
    Colors.teal,
  ),
  MessageType.image: FavoriteTypeStyle(
    HugeIcons.strokeRoundedImage01,
    Colors.purple,
  ),
  MessageType.audio: FavoriteTypeStyle(
    HugeIcons.strokeRoundedMic01,
    Colors.orange,
  ),
  MessageType.video: FavoriteTypeStyle(
    HugeIcons.strokeRoundedVideo01,
    Colors.red,
  ),
  MessageType.file: FavoriteTypeStyle(
    HugeIcons.strokeRoundedFile02,
    Colors.indigo,
  ),
  MessageType.emoji: FavoriteTypeStyle(
    HugeIcons.strokeRoundedHappy01,
    Colors.amber,
  ),
  MessageType.location: FavoriteTypeStyle(
    HugeIcons.strokeRoundedLocation01,
    Colors.green,
  ),
  MessageType.card: FavoriteTypeStyle(HugeIcons.strokeRoundedBadge, Colors.cyan),
  MessageType.system: FavoriteTypeStyle(
    HugeIcons.strokeRoundedInformationCircle,
    Colors.blueGrey,
  ),
};

/// 获取消息类型的展示样式
FavoriteTypeStyle favoriteTypeStyle(MessageType type) {
  return favoriteTypeStyles[type] ??
      const FavoriteTypeStyle(HugeIcons.strokeRoundedFile01, Colors.blueGrey);
}

/// 获取消息类型在明暗主题下适配的展示颜色
Color favoriteTypeColor(BuildContext context, MessageType type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final material = favoriteTypeStyle(type).color;
  return isDark ? material.shade300 : material.shade600;
}

/// 获取消息类型的本地化名称
String favoriteTypeLabel(MessageType type) {
  return switch (type) {
    MessageType.text => 'favorite_type_text'.tr(),
    MessageType.richText => 'favorite_type_rich_text'.tr(),
    MessageType.image => 'favorite_type_image'.tr(),
    MessageType.audio => 'favorite_type_audio'.tr(),
    MessageType.video => 'favorite_type_video'.tr(),
    MessageType.file => 'favorite_type_file'.tr(),
    MessageType.emoji => 'favorite_type_emoji'.tr(),
    MessageType.location => 'favorite_type_location'.tr(),
    MessageType.card => 'favorite_type_card'.tr(),
    MessageType.codeSnippet => 'favorite_type_code'.tr(),
    MessageType.system => 'favorite_type_system'.tr(),
  };
}

/// 是否为协议媒体占位标记（如 `[image]`、`[IMAGE]`、`[empty]`）
bool isPlaceholderSummary(String text) {
  const markers = {
    '[image]',
    '[audio]',
    '[video]',
    '[file]',
    '[emoji]',
    '[location]',
    '[card]',
    '[system]',
    '[empty]',
  };
  return markers.contains(text.trim().toLowerCase());
}

/// 获取收藏项的展示文本
///
/// 协议占位标记（如 `[image]`）对用户无意义，映射为本地化类型标签。
String displayFavoriteSummary(ChatFavorite item, String text) {
  final trimmed = text.trim();
  if (isPlaceholderSummary(trimmed)) {
    return favoriteTypeLabel(item.messageType);
  }
  return trimmed;
}

String formatFavoriteDate(DateTime? dt) {
  if (dt == null) return '--';

  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
