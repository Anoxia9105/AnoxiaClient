// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'official_room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 构建纯前端虚拟官方房间。
///
/// 该房间不来自服务端，仅用于展示功能引导 / 帮助，不支持聊天、通话与成员管理。

@ProviderFor(officialRoom)
final officialRoomProvider = OfficialRoomProvider._();

/// 构建纯前端虚拟官方房间。
///
/// 该房间不来自服务端，仅用于展示功能引导 / 帮助，不支持聊天、通话与成员管理。

final class OfficialRoomProvider
    extends $FunctionalProvider<ChatRoomVO, ChatRoomVO, ChatRoomVO>
    with $Provider<ChatRoomVO> {
  /// 构建纯前端虚拟官方房间。
  ///
  /// 该房间不来自服务端，仅用于展示功能引导 / 帮助，不支持聊天、通话与成员管理。
  OfficialRoomProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'officialRoomProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$officialRoomHash();

  @$internal
  @override
  $ProviderElement<ChatRoomVO> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRoomVO create(Ref ref) {
    return officialRoom(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRoomVO value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRoomVO>(value),
    );
  }
}

String _$officialRoomHash() => r'7c23006ff00f558258c5e317235b73300ea6dff7';
