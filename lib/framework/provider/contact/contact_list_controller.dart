import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_list_controller.g.dart';

/// 联系人列表服务
///
/// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
/// 支持在线状态更新和拼音排序分组。
///
/// 采用 keepAlive 模式，确保联系人缓存在全局共享。
@Riverpod(keepAlive: true)
class ContactListService extends _$ContactListService {
  @override
  FutureOr<Map<int, ChatContactVO>> build() {
    return _fetchContacts();
  }

  /// 从后端获取联系人列表
  ///
  /// 返回 Map 结构便于 O(1) 按 contactId 查找
  Future<Map<int, ChatContactVO>> _fetchContacts() async {
    final response = await DioClient().get(API.contactList);
    final list = (response.data["data"] as List)
        .map((e) => ChatContactVO.fromJson(e))
        .toList();

    return {for (var item in list) item.contactId!: item};
  }

  /// 局部更新联系人的在线状态
  ///
  /// 由 WebSocket 在线状态推送触发，避免全量刷新
  void updateOnlineStatus(int userId, bool isOnline) {
    final currentAsync = state;
    if (currentAsync is AsyncData<Map<int, ChatContactVO>>) {
      final contactMap = currentAsync.value;

      if (contactMap.containsKey(userId)) {
        final updatedContact = contactMap[userId]!.copyWith(
          onlineStatus: isOnline,
        );

        state = AsyncData({...contactMap, userId: updatedContact});
        log.info("👤 联系人 $userId 状态同步: ${isOnline ? '在线' : '离线'}");
      }
    }
  }

  /// 刷新联系人列表
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchContacts());
  }
}

/// 联系人拼音排序分组
///
/// 按联系人昵称/备注的首字母进行 A-Z 分组，
/// 中文姓名自动转换为拼音后取首字母。
@Riverpod(keepAlive: true)
Future<Map<String, List<ChatContactVO>>> sortedContactGroups(Ref ref) async {
  final contactsAsync = ref.watch(contactListServiceProvider);
  final contactMap = contactsAsync.value ?? {};
  if (contactMap.isEmpty) return {};

  final List<ChatContactVO> contacts = contactMap.values.toList();

  // 按拼音首字母排序
  final sortedList = List<ChatContactVO>.from(contacts)
    ..sort((a, b) {
      String nameA = PinyinHelper.getPinyin(a.remark ?? a.nickName ?? "#");
      String nameB = PinyinHelper.getPinyin(b.remark ?? b.nickName ?? "#");
      return nameA.compareTo(nameB);
    });

  // 按首字母分组
  final Map<String, List<ChatContactVO>> groupMap = {};

  for (var contact in sortedList) {
    String displayName = contact.remark ?? contact.nickName ?? "#";
    String tag = PinyinHelper.getFirstWordPinyin(displayName)
        .substring(0, 1)
        .toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(tag)) tag = "#";
    groupMap.putIfAbsent(tag, () => []).add(contact);
  }

  // 排序分组键（# 组排在最后）
  final sortedKeys = groupMap.keys.toList()
    ..sort((a, b) {
      if (a == "#") return 1;
      if (b == "#") return -1;
      return a.compareTo(b);
    });

  return {for (var k in sortedKeys) k: groupMap[k]!};
}
