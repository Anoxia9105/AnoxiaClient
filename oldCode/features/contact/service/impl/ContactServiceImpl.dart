import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/domain/ContactRequest.dart';
import 'package:notepadclient/features/contact/service/IContactService.dart';

import '../../../../core/domain/Contact.dart';

class ContactServiceImpl extends ApiBase implements IContactService {
  @override
  Future<List<Contact>> getContactList(num? userId) {
    return handleResponse<List<Contact>>(
      get(pathContactList(), queryParameters: {'userId': userId}),
      parser: (data) {
        final list = data as List;
        return list.map((e) => Contact.fromJson(e)).toList();
      },
      defaultValue: [],
    );
  }

  @override
  Future<List<ContactRequest>> getContactRequestList(num? userId) {
    return handleResponse<List<ContactRequest>>(
      get(pathContactRequestList(), queryParameters: {'userId': userId}),
      parser: (data) {
        final list = data as List;
        return list.map((e) => ContactRequest.fromJson(e)).toList();
      },
      defaultValue: [],
    );
  }

  @override
  Future<bool> updateContactStatus(num? requestId, num? status) async {
    if (requestId == null || status == null) return false;
    return handleResponse<bool>(
      get(
        pathContactRequestUpdate(),
        queryParameters: {'requestId': requestId, 'status': status},
      ),
      parser: (data) {
        return data;
      },
      defaultValue: false,
    );
  }
}
