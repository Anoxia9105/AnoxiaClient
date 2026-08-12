import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';

import '../../domain/repositories/app_background_repository.dart';
import '../../framework/domain/app_background.dart';
import '../../framework/network/dio_client.dart';

class AppBackgroundRepositoryImpl implements AppBackgroundRepository {
  final DioClient _client;

  AppBackgroundRepositoryImpl(this._client);

  @override
  Future<AppBackgroundState> fetch() async {
    final response = await _client.get('/user/backgrounds');
    return _parse(response.data);
  }

  @override
  Future<AppBackgroundState> upload({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final response = await _client.uploadFile(
        '/user/backgrounds',
        file: XFile.fromData(bytes, name: fileName),
        contentType: _contentType(fileName),
        onSendProgress: onProgress,
      );
      return _parse(response.data);
    } on DioException catch (error) {
      final responseBody = error.response?.data;
      if (responseBody is Map && responseBody['msg'] != null) {
        throw AppBackgroundException(responseBody['msg'].toString());
      }
      if (error.response?.statusCode == 413) {
        throw const AppBackgroundException.localized(
          'settings_bg_media_gateway_limit',
        );
      }
      if (error.type == DioExceptionType.sendTimeout) {
        throw const AppBackgroundException.localized(
          'settings_bg_media_upload_timeout',
        );
      }
      rethrow;
    }
  }

  @override
  Future<AppBackgroundState> updatePreference({
    required int? activeAssetId,
    required double surfaceOpacity,
  }) async {
    final response = await _client.put(
      '/user/backgrounds/preference',
      data: {'activeAssetId': activeAssetId, 'surfaceOpacity': surfaceOpacity},
    );
    return _parse(response.data);
  }

  @override
  Future<AppBackgroundState> delete(int assetId) async {
    final response = await _client.delete('/user/backgrounds/$assetId');
    return _parse(response.data);
  }

  AppBackgroundState _parse(dynamic responseBody) {
    if (responseBody is Map && responseBody['code'] != 200) {
      final message = responseBody['msg']?.toString().trim();
      if (message?.isNotEmpty == true) {
        throw AppBackgroundException(message!);
      }
      throw const AppBackgroundException.localized(
        'settings_bg_media_upload_failed',
      );
    }
    if (responseBody is! Map) {
      throw const FormatException('Invalid app background response');
    }
    final data = responseBody['data'];
    if (data is! Map) {
      throw const FormatException('Missing app background data');
    }
    return AppBackgroundState.fromJson(data.cast<String, dynamic>());
  }

  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'webm' => 'video/webm',
      'mp4' => 'video/mp4',
      _ => throw const AppBackgroundException.localized(
        'settings_bg_media_unsupported',
      ),
    };
  }
}
