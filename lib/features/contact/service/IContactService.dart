abstract class IContactService {
  /// 获取联系人列表
  Future<List<String>> getContactList(num? userId);
}