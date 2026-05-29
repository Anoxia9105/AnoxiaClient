import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_selection_controller.g.dart';

/// 联系人视图类型枚举
///
/// 定义联系人页面的不同视图状态
enum ContactViewType {
  /// 无选中状态
  none,

  /// 新的朋友页面
  newFriends,

  /// 群聊列表页面
  groups,

  /// 联系人详情页面
  contactDetail,
}

/// 联系人选择状态
///
/// 管理联系人页面的选中状态，包括当前视图类型和选中的联系人
class ContactSelectionState {
  /// 当前视图类型
  final ContactViewType viewType;

  /// 选中的联系人（仅在 contactDetail 视图时有值）
  final ChatContactVO? selectedContact;

  /// 创建联系人选择状态
  ContactSelectionState({
    this.viewType = ContactViewType.none,
    this.selectedContact,
  });
}

/// 联系人选择控制器
///
/// 管理联系人页面的导航状态，支持切换不同视图
@riverpod
class ContactSelection extends _$ContactSelection {
  @override
  ContactSelectionState build() => ContactSelectionState();

  /// 选中"新的朋友"视图
  void selectNewFriends() {
    state = ContactSelectionState(viewType: ContactViewType.newFriends);
  }

  /// 选中指定联系人，进入详情视图
  ///
  /// [contact] 被选中的联系人
  void selectContact(ChatContactVO contact) {
    state = ContactSelectionState(
      viewType: ContactViewType.contactDetail,
      selectedContact: contact,
    );
  }

  /// 选中"群聊"视图
  void selectGroups() {
    state = ContactSelectionState(viewType: ContactViewType.groups);
  }

  /// 清空选中状态
  ///
  /// 用于删除联系人后返回列表视图
  void clearSelection() {
    state = ContactSelectionState();
  }
}