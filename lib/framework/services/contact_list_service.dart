import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_list_service.g.dart';

@riverpod
class ContactListService extends _$ContactListService {
  @override
  FutureOr<List<ChatContactVO>> build() {
    return _fetchContacts();
  }

  Future<List<ChatContactVO>> _fetchContacts() async {
    final response = await DioClient().get('/contact/list');
    return (response.data["data"] as List)
        .map((e) => ChatContactVO.fromJson(e))
        .toList();
  }

  /// 手动刷新方法（例如下拉刷新时调用）
  Future<void> refresh() async {
    state = const AsyncValue.loading(); // 先展示加载状态
    state = await AsyncValue.guard(() => _fetchContacts()); // 获取新数据并更新
  }
}



// 进行拼音排序和分组的 Provider
@riverpod
Future<Map<String, List<ChatContactVO>>> sortedContactGroups(Ref ref) async {
  // 1. 关键：监听你的 ContactListService
  // 当 ContactListService 调用 refresh() 导致数据变化时，这里会自动重新执行
  final List<ChatContactVO> contacts = await ref.watch(contactListServiceProvider.future);

  // 2. 进行拼音排序和分组逻辑 (逻辑同前，保持纯净，不写 UI)
  final Map<String, List<ChatContactVO>> groupMap = {};

  // 排序
  final sortedList = List<ChatContactVO>.from(contacts)..sort((a, b) {
    String nameA = PinyinHelper.getPinyin(a.remark ?? a.nickName ?? "#");
    String nameB = PinyinHelper.getPinyin(b.remark ?? b.nickName ?? "#");
    return nameA.compareTo(nameB);
  });

  // 分组
  for (var contact in sortedList) {
    String displayName = contact.remark ?? contact.nickName ?? "#";
    String pinyin = PinyinHelper.getFirstWordPinyin(displayName);
    String tag = pinyin.substring(0, 1).toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(tag)) tag = "#";

    groupMap.putIfAbsent(tag, () => []).add(contact);
  }

  // 对 Key 排序
  final sortedKeys = groupMap.keys.toList()..sort((a, b) {
    if (a == "#") return 1;
    if (b == "#") return -1;
    return a.compareTo(b);
  });

  return { for (var k in sortedKeys) k : groupMap[k]! };
}