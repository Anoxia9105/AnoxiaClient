// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 获取联系人详情
///
/// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）

@ProviderFor(contactDetailData)
const contactDetailDataProvider = ContactDetailDataFamily._();

/// 获取联系人详情
///
/// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）

final class ContactDetailDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChatContactDetailVO>,
          ChatContactDetailVO,
          FutureOr<ChatContactDetailVO>
        >
    with
        $FutureModifier<ChatContactDetailVO>,
        $FutureProvider<ChatContactDetailVO> {
  /// 获取联系人详情
  ///
  /// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）
  const ContactDetailDataProvider._({
    required ContactDetailDataFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactDetailDataProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactDetailDataHash();

  @override
  String toString() {
    return r'contactDetailDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ChatContactDetailVO> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChatContactDetailVO> create(Ref ref) {
    final argument = this.argument as int;
    return contactDetailData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContactDetailDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactDetailDataHash() => r'f93acf54fc456d3f0479bbd3adf6b7dd6692d384';

/// 获取联系人详情
///
/// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）

final class ContactDetailDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ChatContactDetailVO>, int> {
  const ContactDetailDataFamily._()
    : super(
        retry: null,
        name: r'contactDetailDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 获取联系人详情
  ///
  /// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）

  ContactDetailDataProvider call(int userId) =>
      ContactDetailDataProvider._(argument: userId, from: this);

  @override
  String toString() => r'contactDetailDataProvider';
}

/// 联系人聊天按钮加载状态
///
/// 控制"发消息"按钮的加载状态，防止重复点击

@ProviderFor(ContactChatLoading)
const contactChatLoadingProvider = ContactChatLoadingProvider._();

/// 联系人聊天按钮加载状态
///
/// 控制"发消息"按钮的加载状态，防止重复点击
final class ContactChatLoadingProvider
    extends $NotifierProvider<ContactChatLoading, bool> {
  /// 联系人聊天按钮加载状态
  ///
  /// 控制"发消息"按钮的加载状态，防止重复点击
  const ContactChatLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactChatLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactChatLoadingHash();

  @$internal
  @override
  ContactChatLoading create() => ContactChatLoading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$contactChatLoadingHash() =>
    r'5c569831999b4543ad3278ab1d999cbcf9aa99c4';

/// 联系人聊天按钮加载状态
///
/// 控制"发消息"按钮的加载状态，防止重复点击

abstract class _$ContactChatLoading extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
