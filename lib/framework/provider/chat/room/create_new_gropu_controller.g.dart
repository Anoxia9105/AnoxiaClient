// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_new_gropu_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 多选框选择用

@ProviderFor(SelectedContactIds)
final selectedContactIdsProvider = SelectedContactIdsProvider._();

/// 多选框选择用
final class SelectedContactIdsProvider
    extends $NotifierProvider<SelectedContactIds, Set<int>> {
  /// 多选框选择用
  SelectedContactIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedContactIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedContactIdsHash();

  @$internal
  @override
  SelectedContactIds create() => SelectedContactIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$selectedContactIdsHash() =>
    r'b7c17f5f3cfbbf32b6f4912133587b0b50d31d9c';

/// 多选框选择用

abstract class _$SelectedContactIds extends $Notifier<Set<int>> {
  Set<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<int>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<int>, Set<int>>,
              Set<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 创建群聊控制器
///
/// 负责发起创建群聊的请求和处理结果

@ProviderFor(CreateGroupController)
final createGroupControllerProvider = CreateGroupControllerProvider._();

/// 创建群聊控制器
///
/// 负责发起创建群聊的请求和处理结果
final class CreateGroupControllerProvider
    extends $AsyncNotifierProvider<CreateGroupController, ChatRoomVO?> {
  /// 创建群聊控制器
  ///
  /// 负责发起创建群聊的请求和处理结果
  CreateGroupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGroupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGroupControllerHash();

  @$internal
  @override
  CreateGroupController create() => CreateGroupController();
}

String _$createGroupControllerHash() =>
    r'd607555be4da764d4b90d1f83966eda10d9acfec';

/// 创建群聊控制器
///
/// 负责发起创建群聊的请求和处理结果

abstract class _$CreateGroupController extends $AsyncNotifier<ChatRoomVO?> {
  FutureOr<ChatRoomVO?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChatRoomVO?>, ChatRoomVO?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatRoomVO?>, ChatRoomVO?>,
              AsyncValue<ChatRoomVO?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
