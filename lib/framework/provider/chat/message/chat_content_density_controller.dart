import 'dart:math' as math;

import 'package:anoxia/common/utils/sp_util.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

enum ChatContentDensity {
  comfortable('comfortable'),
  compact('compact'),
  flat('flat');

  const ChatContentDensity(this.storageValue);

  final String storageValue;
}

ChatContentDensity parseChatContentDensity(Object? value) {
  return ChatContentDensity.values.firstWhere(
    (density) => density.storageValue == value,
    orElse: () => ChatContentDensity.comfortable,
  );
}

class ChatMessageLayout {
  const ChatMessageLayout({
    required this.placeOnLeft,
    required this.verticalMargin,
    required this.avatarSize,
    required this.avatarGap,
    required this.headerInset,
    required this.trailingSpace,
    required this.horizontalPadding,
  });

  final bool placeOnLeft;
  final double verticalMargin;
  final double avatarSize;
  final double avatarGap;
  final double headerInset;
  final double trailingSpace;
  final double horizontalPadding;
}

ChatMessageLayout resolveChatMessageLayout(
  ChatContentDensity density, {
  required bool isCurrentUser,
  required double baseHorizontalPadding,
}) {
  return switch (density) {
    ChatContentDensity.comfortable => ChatMessageLayout(
      placeOnLeft: !isCurrentUser,
      verticalMargin: 6,
      avatarSize: 32,
      avatarGap: 6,
      headerInset: 45,
      trailingSpace: 20,
      horizontalPadding: baseHorizontalPadding,
    ),
    ChatContentDensity.compact => ChatMessageLayout(
      placeOnLeft: !isCurrentUser,
      verticalMargin: 2,
      avatarSize: 28,
      avatarGap: 4,
      headerInset: 37,
      trailingSpace: 10,
      horizontalPadding: math.min(baseHorizontalPadding, 32),
    ),
    ChatContentDensity.flat => ChatMessageLayout(
      placeOnLeft: true,
      verticalMargin: 4,
      avatarSize: 30,
      avatarGap: 8,
      headerInset: 38,
      trailingSpace: 8,
      horizontalPadding: math.min(baseHorizontalPadding, 16),
    ),
  };
}

class ChatContentDensityController
    extends legacy.StateNotifier<ChatContentDensity> {
  static const _storageKey = 'chat_content_density';

  ChatContentDensityController() : super(_load());

  static ChatContentDensity _load() {
    return parseChatContentDensity(
      SPUtil.instance.get(
        _storageKey,
        defValue: ChatContentDensity.comfortable.storageValue,
      ),
    );
  }

  void setDensity(ChatContentDensity density) {
    if (state == density) return;
    state = density;
    SPUtil.instance.set(_storageKey, density.storageValue);
  }
}

final chatContentDensityProvider =
    legacy.StateNotifierProvider<
      ChatContentDensityController,
      ChatContentDensity
    >((ref) => ChatContentDensityController());
