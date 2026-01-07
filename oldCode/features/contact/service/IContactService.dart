import 'package:notepadclient/core/domain/Contact.dart';
import 'package:notepadclient/core/domain/ContactRequest.dart';

abstract class IContactService {
  /// 获取联系人列表
  Future<List<Contact>> getContactList(num? userId);

  /// 获取联系人申请列表
  Future<List<ContactRequest>> getContactRequestList(num? userId);


  /// 修改申请联系人状态
  Future<bool> updateContactStatus(num? requestId, num? status);
}