import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/features/contact/service/IContactService.dart';

class ContactServiceImpl extends ApiBase implements IContactService {
  @override
  Future<List<String>> getContactList(num? userId) {
    throw UnimplementedError();
  }

}