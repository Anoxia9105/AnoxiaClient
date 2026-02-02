import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_list_controller.g.dart';

@riverpod
class ContactListService extends _$ContactListService {
  @override
  FutureOr<Map<int, ChatContactVO>> build() {
    return _fetchContacts();
  }

  Future<Map<int, ChatContactVO>> _fetchContacts() async {
    final response = await DioClient().get('/contact/list');
    final list = (response.data["data"] as List)
        .map((e) => ChatContactVO.fromJson(e))
        .toList();

    // 💡 将 List 转为 Map，key 为 contactId
    return {for (var item in list) item.contactId!: item};
  }

  /// 局部更新在线状态
  void updateOnlineStatus(int userId, bool isOnline) {
    final currentAsync = state;
    if (currentAsync is AsyncData<Map<int, ChatContactVO>>) {
      final contactMap = currentAsync.value;

      // 💡 直接通过 Key 查找，不再需要 indexWhere
      if (contactMap.containsKey(userId)) {
        final updatedContact = contactMap[userId]!.copyWith(
          onlineStatus: isOnline,
        );

        // 更新 Map 并触发状态变更
        state = AsyncData({...contactMap, userId: updatedContact});

        log.info("👤 联系人 $userId 状态同步: ${isOnline ? '在线' : '离线'}");
      }
    }
  }

  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchContacts());
  }
}

// 进行拼音排序和分组的 Provider
@riverpod
Future<Map<String, List<ChatContactVO>>> sortedContactGroups(Ref ref) async {
  final contactsAsync = ref.watch(contactListServiceProvider);
  // 💡 获取 Map 里的所有对象
  final contactMap = contactsAsync.value ?? {};
  if (contactMap.isEmpty) return {};

  final List<ChatContactVO> contacts = contactMap.values.toList();

  final Map<String, List<ChatContactVO>> groupMap = {};

  // 排序逻辑 (保持不变，但操作的是 Map 转换后的 List)
  final sortedList = List<ChatContactVO>.from(contacts)
    ..sort((a, b) {
      String nameA = PinyinHelper.getPinyin(a.remark ?? a.nickName ?? "#");
      String nameB = PinyinHelper.getPinyin(b.remark ?? b.nickName ?? "#");
      return nameA.compareTo(nameB);
    });

  // 分组逻辑 (保持不变)...
  for (var contact in sortedList) {
    String displayName = contact.remark ?? contact.nickName ?? "#";
    String tag = PinyinHelper.getFirstWordPinyin(
      displayName,
    ).substring(0, 1).toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(tag)) tag = "#";
    groupMap.putIfAbsent(tag, () => []).add(contact);
  }

  final sortedKeys = groupMap.keys.toList()
    ..sort((a, b) {
      if (a == "#") return 1;
      if (b == "#") return -1;
      return a.compareTo(b);
    });

  return {for (var k in sortedKeys) k: groupMap[k]!};
}
