import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_selection_controller.g.dart';

enum ContactViewType { none, newFriends, groups, contactDetail }

class ContactSelectionState {
  final ContactViewType viewType;
  final ChatContactVO? selectedContact;

  ContactSelectionState({
    this.viewType = ContactViewType.none,
    this.selectedContact,
  });
}

@riverpod
class ContactSelection extends _$ContactSelection {
  @override
  ContactSelectionState build() => ContactSelectionState();

  // 选中“新的朋友”
  void selectNewFriends() {
    state = ContactSelectionState(viewType: ContactViewType.newFriends);
  }

  // 选中“联系人”
  void selectContact(ChatContactVO contact) {
    state = ContactSelectionState(
      viewType: ContactViewType.contactDetail,
      selectedContact: contact,
    );
  }
  
  // 选中“群聊”
  void selectGroups() {
    state = ContactSelectionState(viewType: ContactViewType.groups);
  }

  // 清空选中（如删除联系人后）
  void clearSelection() {
    state = ContactSelectionState();
  }
}