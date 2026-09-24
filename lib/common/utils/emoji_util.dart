import 'package:characters/characters.dart';

/// Unicode Emoji 判断工具。
///
/// 聊天发送、气泡布局和消息渲染必须共用同一套规则，避免同一个字符在不同
/// 阶段被分别判定为文本与 Emoji。
abstract final class EmojiUtil {
  /// 判断 [value] 是否仅包含一个 Emoji 字素簇。
  ///
  /// 支持变体选择符、肤色修饰符、区域旗帜、键帽与 ZWJ 组合序列。
  static bool isSingleEmoji(String value) {
    final text = value.trim();
    if (text.isEmpty) return false;

    final graphemes = text.characters;
    if (graphemes.length != 1) return false;

    final runes = graphemes.first.runes.toList(growable: false);
    if (_isKeycapSequence(runes)) return true;

    var containsEmoji = false;
    for (final rune in runes) {
      if (_isEmojiCodePoint(rune)) {
        containsEmoji = true;
        continue;
      }
      if (!_isEmojiContinuation(rune)) return false;
    }
    return containsEmoji;
  }

  static bool _isKeycapSequence(List<int> runes) {
    if (runes.length < 2 || runes.last != 0x20E3) return false;
    final first = runes.first;
    if (first != 0x23 && first != 0x2A && (first < 0x30 || first > 0x39)) {
      return false;
    }
    return runes.skip(1).every((rune) => rune == 0xFE0F || rune == 0x20E3);
  }

  static bool _isEmojiContinuation(int rune) =>
      rune == 0x200D ||
      rune == 0xFE0E ||
      rune == 0xFE0F ||
      (rune >= 0xE0020 && rune <= 0xE007F);

  static bool _isEmojiCodePoint(int rune) =>
      rune == 0x00A9 ||
      rune == 0x00AE ||
      rune == 0x203C ||
      rune == 0x2049 ||
      rune == 0x2122 ||
      rune == 0x2139 ||
      (rune >= 0x2194 && rune <= 0x2199) ||
      (rune >= 0x21A9 && rune <= 0x21AA) ||
      (rune >= 0x231A && rune <= 0x231B) ||
      rune == 0x2328 ||
      rune == 0x23CF ||
      (rune >= 0x23E9 && rune <= 0x23F3) ||
      (rune >= 0x23F8 && rune <= 0x23FA) ||
      rune == 0x24C2 ||
      (rune >= 0x25AA && rune <= 0x25AB) ||
      rune == 0x25B6 ||
      rune == 0x25C0 ||
      (rune >= 0x25FB && rune <= 0x25FE) ||
      (rune >= 0x2600 && rune <= 0x27BF) ||
      (rune >= 0x2934 && rune <= 0x2935) ||
      (rune >= 0x2B05 && rune <= 0x2B07) ||
      (rune >= 0x2B1B && rune <= 0x2B1C) ||
      rune == 0x2B50 ||
      rune == 0x2B55 ||
      rune == 0x3030 ||
      rune == 0x303D ||
      rune == 0x3297 ||
      rune == 0x3299 ||
      (rune >= 0x1F000 && rune <= 0x1F02F) ||
      (rune >= 0x1F0A0 && rune <= 0x1F0FF) ||
      (rune >= 0x1F170 && rune <= 0x1F19A) ||
      (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
      (rune >= 0x1F200 && rune <= 0x1F2FF) ||
      (rune >= 0x1F300 && rune <= 0x1FAFF);
}
