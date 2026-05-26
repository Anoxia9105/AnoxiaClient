import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../framework/domain/ChatContactVO.dart';
import '../../../framework/domain/ChatRoomVO.dart';
import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_list_controller.dart';

part 'desktop_search_controller.g.dart';

/// 聚合搜索结果的数据结构
class SearchResultState {
  final String query;
  final List<ChatRoomVO> rooms;
  final List<ChatContactVO> contacts;

  SearchResultState({
    required this.query,
    required this.rooms,
    required this.contacts,
  });
}

@riverpod
class DesktopSearchController extends _$DesktopSearchController {
  @override
  SearchResultState build() {
    final q = '';
    return SearchResultState(query: q, rooms: [], contacts: []);
  }

  void updateQuery(String newQuery) {
    final q = newQuery.trim().toLowerCase();
    if (q.isEmpty) {
      state = SearchResultState(query: '', rooms: [], contacts: []);
      return;
    }

    // 联动依赖现有的这两个旧版/新版 Provider 
    final rooms = ref.read(roomListServiceProvider).value ?? <ChatRoomVO>[];
    final contactsMap = ref.read(contactListServiceProvider).value ?? <int, ChatContactVO>{};

    final roomResults = rooms.where((r) {
      final roomName = (r.roomName ?? '').toLowerCase();
      final lastMsg = (r.lastMessage?.content ?? '').toLowerCase();
      return roomName.contains(q) || lastMsg.contains(q);
    }).take(8).toList();

    final contactResults = contactsMap.values.where((c) {
      final name = (c.nickName ?? '').toLowerCase();
      final remark = (c.remark ?? '').toLowerCase();
      final idText = (c.contactId?.toString() ?? '');
      return name.contains(q) || remark.contains(q) || idText.contains(q);
    }).take(8).toList();

    state = SearchResultState(
      query: newQuery,
      rooms: roomResults,
      contacts: contactResults,
    );
  }
}