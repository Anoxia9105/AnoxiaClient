// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 联系人列表服务
///
/// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
/// 支持在线状态更新和拼音排序分组。
///
/// 采用 keepAlive 模式，确保联系人缓存在全局共享。

@ProviderFor(ContactListService)
const contactListServiceProvider = ContactListServiceProvider._();

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
  const ContactListServiceProvider._()
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
    r'acda1d2d0e2e11a84e05633e1bf36324c998552a';

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
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}

/// 联系人拼音排序分组
///
/// 按联系人昵称/备注的首字母进行 A-Z 分组，
/// 中文姓名自动转换为拼音后取首字母。

@ProviderFor(sortedContactGroups)
const sortedContactGroupsProvider = SortedContactGroupsProvider._();

/// 联系人拼音排序分组
///
/// 按联系人昵称/备注的首字母进行 A-Z 分组，
/// 中文姓名自动转换为拼音后取首字母。

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
  const SortedContactGroupsProvider._()
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
    r'dbd8a9ed356bf96f9b79425f6d3d580754b121aa';
