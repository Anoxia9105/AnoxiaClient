// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_member_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 获取指定房间的成员列表

@ProviderFor(roomMembers)
const roomMembersProvider = RoomMembersFamily._();

/// 获取指定房间的成员列表

final class RoomMembersProvider
    extends
        $FunctionalProvider<
          List<ChatRoomMemberVO>,
          List<ChatRoomMemberVO>,
          List<ChatRoomMemberVO>
        >
    with $Provider<List<ChatRoomMemberVO>> {
  /// 获取指定房间的成员列表
  const RoomMembersProvider._({
    required RoomMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMembersHash();

  @override
  String toString() {
    return r'roomMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ChatRoomMemberVO>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ChatRoomMemberVO> create(Ref ref) {
    final argument = this.argument as String;
    return roomMembers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatRoomMemberVO> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatRoomMemberVO>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMembersHash() => r'2a790f6413245bf6a6921b0dbbf7365b59827693';

/// 获取指定房间的成员列表

final class RoomMembersFamily extends $Family
    with $FunctionalFamilyOverride<List<ChatRoomMemberVO>, String> {
  const RoomMembersFamily._()
    : super(
        retry: null,
        name: r'roomMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取指定房间的成员列表

  RoomMembersProvider call(String roomId) =>
      RoomMembersProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMembersProvider';
}

/// 获取指定房间的成员数量

@ProviderFor(roomMemberCount)
const roomMemberCountProvider = RoomMemberCountFamily._();

/// 获取指定房间的成员数量

final class RoomMemberCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 获取指定房间的成员数量
  const RoomMemberCountProvider._({
    required RoomMemberCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomMemberCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMemberCountHash();

  @override
  String toString() {
    return r'roomMemberCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as String;
    return roomMemberCount(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMemberCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMemberCountHash() => r'ff9f358dec5bcee6e22a07a79f937f701a5fb1e8';

/// 获取指定房间的成员数量

final class RoomMemberCountFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  const RoomMemberCountFamily._()
    : super(
        retry: null,
        name: r'roomMemberCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取指定房间的成员数量

  RoomMemberCountProvider call(String roomId) =>
      RoomMemberCountProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMemberCountProvider';
}

/// 获取指定房间内某个用户的成员信息
///
/// 使用 Record 作为参数避免定义额外的参数类

@ProviderFor(roomMember)
const roomMemberProvider = RoomMemberFamily._();

/// 获取指定房间内某个用户的成员信息
///
/// 使用 Record 作为参数避免定义额外的参数类

final class RoomMemberProvider
    extends
        $FunctionalProvider<
          ChatRoomMemberVO?,
          ChatRoomMemberVO?,
          ChatRoomMemberVO?
        >
    with $Provider<ChatRoomMemberVO?> {
  /// 获取指定房间内某个用户的成员信息
  ///
  /// 使用 Record 作为参数避免定义额外的参数类
  const RoomMemberProvider._({
    required RoomMemberFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'roomMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMemberHash();

  @override
  String toString() {
    return r'roomMemberProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatRoomMemberVO?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatRoomMemberVO? create(Ref ref) {
    final argument = this.argument as (String, int);
    return roomMember(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRoomMemberVO? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRoomMemberVO?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMemberHash() => r'79d84765f3664983b0827033dda8b48ac50404cc';

/// 获取指定房间内某个用户的成员信息
///
/// 使用 Record 作为参数避免定义额外的参数类

final class RoomMemberFamily extends $Family
    with $FunctionalFamilyOverride<ChatRoomMemberVO?, (String, int)> {
  const RoomMemberFamily._()
    : super(
        retry: null,
        name: r'roomMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 获取指定房间内某个用户的成员信息
  ///
  /// 使用 Record 作为参数避免定义额外的参数类

  RoomMemberProvider call((String, int) args) =>
      RoomMemberProvider._(argument: args, from: this);

  @override
  String toString() => r'roomMemberProvider';
}

/// 判断指定用户在某房间是否是管理员

@ProviderFor(isRoomAdmin)
const isRoomAdminProvider = IsRoomAdminFamily._();

/// 判断指定用户在某房间是否是管理员

final class IsRoomAdminProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 判断指定用户在某房间是否是管理员
  const IsRoomAdminProvider._({
    required IsRoomAdminFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'isRoomAdminProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isRoomAdminHash();

  @override
  String toString() {
    return r'isRoomAdminProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as (String, int);
    return isRoomAdmin(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsRoomAdminProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isRoomAdminHash() => r'bc2285b2e86695677d130a56a88db97849f2c537';

/// 判断指定用户在某房间是否是管理员

final class IsRoomAdminFamily extends $Family
    with $FunctionalFamilyOverride<bool, (String, int)> {
  const IsRoomAdminFamily._()
    : super(
        retry: null,
        name: r'isRoomAdminProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 判断指定用户在某房间是否是管理员

  IsRoomAdminProvider call((String, int) args) =>
      IsRoomAdminProvider._(argument: args, from: this);

  @override
  String toString() => r'isRoomAdminProvider';
}

/// 房间成员服务
///
/// 数据结构：Map<roomId, Map<userId, ChatRoomMemberVO>>
/// 双层 Map 实现 O(1) 按房间、按用户 ID 查询
///
/// 采用 keepAlive 模式，跨页面保持缓存避免重复拉取

@ProviderFor(RoomMemberService)
const roomMemberServiceProvider = RoomMemberServiceProvider._();

/// 房间成员服务
///
/// 数据结构：Map<roomId, Map<userId, ChatRoomMemberVO>>
/// 双层 Map 实现 O(1) 按房间、按用户 ID 查询
///
/// 采用 keepAlive 模式，跨页面保持缓存避免重复拉取
final class RoomMemberServiceProvider
    extends
        $NotifierProvider<
          RoomMemberService,
          Map<String, Map<int, ChatRoomMemberVO>>
        > {
  /// 房间成员服务
  ///
  /// 数据结构：Map<roomId, Map<userId, ChatRoomMemberVO>>
  /// 双层 Map 实现 O(1) 按房间、按用户 ID 查询
  ///
  /// 采用 keepAlive 模式，跨页面保持缓存避免重复拉取
  const RoomMemberServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomMemberServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomMemberServiceHash();

  @$internal
  @override
  RoomMemberService create() => RoomMemberService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Map<int, ChatRoomMemberVO>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, Map<int, ChatRoomMemberVO>>>(value),
    );
  }
}

String _$roomMemberServiceHash() => r'af27d283debf8fb65018789a95b479c42333e0b7';

/// 房间成员服务
///
/// 数据结构：Map<roomId, Map<userId, ChatRoomMemberVO>>
/// 双层 Map 实现 O(1) 按房间、按用户 ID 查询
///
/// 采用 keepAlive 模式，跨页面保持缓存避免重复拉取

abstract class _$RoomMemberService
    extends $Notifier<Map<String, Map<int, ChatRoomMemberVO>>> {
  Map<String, Map<int, ChatRoomMemberVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              Map<String, Map<int, ChatRoomMemberVO>>,
              Map<String, Map<int, ChatRoomMemberVO>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, Map<int, ChatRoomMemberVO>>,
                Map<String, Map<int, ChatRoomMemberVO>>
              >,
              Map<String, Map<int, ChatRoomMemberVO>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
