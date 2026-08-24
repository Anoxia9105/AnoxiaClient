import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/contact_repository.dart';
import 'package:anoxia/framework/domain/chat_contact_detail_vo.dart';
import 'package:anoxia/framework/domain/chat_contact_request_vo.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/domain/contact_request.dart';
import 'package:anoxia/framework/domain/user_search_response.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 联系人仓库实现
///
/// 通过本地数据源（SQLite）和远程数据源（HTTP API）提供联系人数据。
/// 实现 [ContactRepository] 抽象接口，供领域层用例使用。
class ContactRepositoryImpl implements ContactRepository {
  final LocalDataSource local;

  ContactRepositoryImpl({required this.local});

  @override
  Stream<List<ChatContactVO>> watchContacts() {
    return local.watchContacts();
  }

  @override
  Future<List<ChatContactVO>> getLocalContacts() async {
    final contacts = await local.getContacts();
    return contacts;
  }

  @override
  Future<List<ChatContactVO>> fetchRemoteContacts() async {
    try {
      final response = await DioClient().get(API.contactList);
      final list = (response.data['data'] as List)
          .map((e) => ChatContactVO.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugLog('[Cache] ContactRepository: sync failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertContacts(List<ChatContactVO> contacts) {
    return local.upsertContacts(contacts);
  }

  @override
  Future<void> updateContactOnlineStatus(int userId, bool isOnline) {
    return local.updateContactOnlineStatus(userId, isOnline);
  }

  @override
  Future<void> deleteContact(int contactId) {
    return local.deleteContact(contactId);
  }

  @override
  Future<ChatContactDetailVO> getContactDetail(int userId) async {
    try {
      final response = await DioClient().get(
        API.contactUserDetail,
        queryParameters: {'userId': userId},
      );
      return ChatContactDetailVO.fromJson(response.data['data']);
    } catch (e) {
      debugLog('[Contact] ContactRepositoryImpl: getContactDetail failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserSearchResponse> searchUsers(
    String name, {
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await DioClient().get(
        API.contactSearch,
        queryParameters: {
          'name': name,
          'pageNum': pageNum,
          'pageSize': pageSize,
        },
      );
      return UserSearchResponse.fromJson(response.data);
    } catch (e) {
      debugLog('[Contact] ContactRepositoryImpl: searchUsers failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChatContactRequestVO>> fetchContactRequests() async {
    try {
      final response = await DioClient().get(API.contactRequest);
      final list = (response.data['data'] as List)
          .map((e) => ChatContactRequestVO.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugLog(
        '[Contact] ContactRepositoryImpl: fetchContactRequests failed: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> handleContactRequest(int requestId, bool isAccepted) async {
    try {
      await DioClient().get(
        API.contactAcceptRequest,
        queryParameters: {
          'requestId': requestId,
          'status': isAccepted ? 1 : 2,
          'source': 0,
        },
      );
    } catch (e) {
      debugLog(
        '[Contact] ContactRepositoryImpl: handleContactRequest failed: $e',
      );
      rethrow;
    }
  }

  @override
  Future<bool> sendContactRequest(int toUserId, String? remark) async {
    try {
      final request = ContactRequest(toUserId: toUserId, remark: remark);
      final response = await DioClient().post(
        API.contactRequestCreate,
        data: request.toJson(),
      );
      final success = response.data['code'] == 200;
      return success;
    } catch (e) {
      debugLog('[Contact] ContactRepositoryImpl: sendContactRequest failed: $e');
      return false;
    }
  }
}
