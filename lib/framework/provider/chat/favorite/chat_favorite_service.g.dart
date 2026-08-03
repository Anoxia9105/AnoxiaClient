// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_favorite_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天收藏列表 Provider

@ProviderFor(chatFavoriteList)
final chatFavoriteListProvider = ChatFavoriteListProvider._();

/// 聊天收藏列表 Provider

final class ChatFavoriteListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatFavorite>>,
          List<ChatFavorite>,
          FutureOr<List<ChatFavorite>>
        >
    with
        $FutureModifier<List<ChatFavorite>>,
        $FutureProvider<List<ChatFavorite>> {
  /// 聊天收藏列表 Provider
  ChatFavoriteListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatFavoriteListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatFavoriteListHash();

  @$internal
  @override
  $FutureProviderElement<List<ChatFavorite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChatFavorite>> create(Ref ref) {
    return chatFavoriteList(ref);
  }
}

String _$chatFavoriteListHash() => r'8f056f01cfaa9bc3ade18aa426a096fcefb12d6e';
