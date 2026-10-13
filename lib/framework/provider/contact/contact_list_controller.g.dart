// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactRefreshFailed)
final contactRefreshFailedProvider = ContactRefreshFailedProvider._();

final class ContactRefreshFailedProvider
    extends $NotifierProvider<ContactRefreshFailed, bool> {
  ContactRefreshFailedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactRefreshFailedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactRefreshFailedHash();

  @$internal
  @override
  ContactRefreshFailed create() => ContactRefreshFailed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$contactRefreshFailedHash() =>
    r'57bacab42bb87f39c0b237b446f6ebc342c342fd';

abstract class _$ContactRefreshFailed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 联系人列表服务
///
/// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
/// 支持在线状态更新和拼音排序分组。
///
/// 采用 keepAlive 模式，确保联系人缓存在全局共享。

@ProviderFor(ContactListService)
final contactListServiceProvider = ContactListServiceProvider._();

/// 联系人列表服务
///
/// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
/// 支持在线状态更新和拼音排序分组。
///
/// 采用 keepAlive 模式，确保联系人缓存在全局共享。
final class ContactListServiceProvider
    extends
        $AsyncNotifierProvider<ContactListService, Map<int, ChatContactVO>> {
  /// 联系人列表服务
  ///
  /// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
  /// 支持在线状态更新和拼音排序分组。
  ///
  /// 采用 keepAlive 模式，确保联系人缓存在全局共享。
  ContactListServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactListServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactListServiceHash();

  @$internal
  @override
  ContactListService create() => ContactListService();
}

String _$contactListServiceHash() =>
    r'7333508453036bd99b36a5a08723f33af12f5e51';

/// 联系人列表服务
///
/// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
/// 支持在线状态更新和拼音排序分组。
///
/// 采用 keepAlive 模式，确保联系人缓存在全局共享。

abstract class _$ContactListService
    extends $AsyncNotifier<Map<int, ChatContactVO>> {
  FutureOr<Map<int, ChatContactVO>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<int, ChatContactVO>>,
              Map<int, ChatContactVO>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<int, ChatContactVO>>,
                Map<int, ChatContactVO>
              >,
              AsyncValue<Map<int, ChatContactVO>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 联系人拼音排序分组
///
/// 按联系人昵称/备注的首字母进行 A-Z 分组，
/// 中文姓名自动转换为拼音后取首字母。
/// 过滤掉当前登录用户自己（不应出现在联系人列表中）。

@ProviderFor(sortedContactGroups)
final sortedContactGroupsProvider = SortedContactGroupsProvider._();

/// 联系人拼音排序分组
///
/// 按联系人昵称/备注的首字母进行 A-Z 分组，
/// 中文姓名自动转换为拼音后取首字母。
/// 过滤掉当前登录用户自己（不应出现在联系人列表中）。

final class SortedContactGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<ChatContactVO>>>,
          Map<String, List<ChatContactVO>>,
          FutureOr<Map<String, List<ChatContactVO>>>
        >
    with
        $FutureModifier<Map<String, List<ChatContactVO>>>,
        $FutureProvider<Map<String, List<ChatContactVO>>> {
  /// 联系人拼音排序分组
  ///
  /// 按联系人昵称/备注的首字母进行 A-Z 分组，
  /// 中文姓名自动转换为拼音后取首字母。
  /// 过滤掉当前登录用户自己（不应出现在联系人列表中）。
  SortedContactGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortedContactGroupsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortedContactGroupsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<ChatContactVO>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<ChatContactVO>>> create(Ref ref) {
    return sortedContactGroups(ref);
  }
}

String _$sortedContactGroupsHash() =>
    r'188e9543e94e2b06d262a37f7274ec1daf556a2f';
