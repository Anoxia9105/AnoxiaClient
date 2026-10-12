import 'dart:math' as math;

import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';

/// 文件上传仓库实现。
///
/// 每个文件使用独立请求和稳定的 clientFileId，避免批量响应部分失败后 URL 错位。
class UploadRepositoryImpl implements UploadRepository {
  static const int _maxConcurrentUploads = 2;

  final Map<String, CancelToken> _activeCancels = {};

  @override
  Future<List<UploadFileResult>> uploadFiles(
    List<XFile> files, {
    required List<String> clientFileIds,
    UploadProgressCallback? onProgress,
    UploadCompletedCallback? onCompleted,
    int? noteId,
  }) async {
    if (files.length != clientFileIds.length) {
      throw ArgumentError('files 与 clientFileIds 数量必须一致');
    }
    if (files.isEmpty) return const [];

    final results = List<UploadFileResult?>.filled(files.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (nextIndex < files.length) {
        final index = nextIndex++;
        final result = await _uploadOne(
          files[index],
          clientFileIds[index],
          onProgress,
          noteId,
        );
        results[index] = result;
        onCompleted?.call(result);
      }
    }

    await Future.wait(
      List.generate(
        math.min(_maxConcurrentUploads, files.length),
        (_) => worker(),
      ),
    );
    return results.cast<UploadFileResult>();
  }

  Future<UploadFileResult> _uploadOne(
    XFile file,
    String clientFileId,
    UploadProgressCallback? onProgress,
    int? noteId,
  ) async {
    final cancelToken = CancelToken();
    _activeCancels[clientFileId]?.cancel('replaced by a new upload attempt');
    _activeCancels[clientFileId] = cancelToken;

    try {
      final response = await DioClient().uploadFile(
        noteId == null ? '/file/uploadV2' : '/file/note/$noteId/image',
        file: file,
        data: {'clientFileId': clientFileId},
        cancelToken: cancelToken,
        onSendProgress: onProgress == null
            ? null
            : (sent, total) => onProgress(clientFileId, sent, total),
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (body is Map && body['code'] == 200 && data is Map) {
        final url = data['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return UploadFileResult(
            clientFileId: clientFileId,
            isSuccess: true,
            url: url,
            coverUrl: data['coverUrl']?.toString(),
            coverSizeBytes: _readInt(data['coverSizeBytes']),
            durationMs: _readInt(data['durationMs']),
            width: _readInt(data['width']),
            height: _readInt(data['height']),
            bitrate: _readInt(data['bitrate']),
            sizeBytes: _readInt(data['sizeBytes']),
            name: data['name']?.toString(),
            mimeType: data['mimeType']?.toString(),
          );
        }
      }
      return UploadFileResult(
        clientFileId: clientFileId,
        isSuccess: false,
        errorCode: data is Map
            ? data['errorCode']?.toString()
            : 'INVALID_RESPONSE',
      );
    } on DioException catch (error, stackTrace) {
      debugLog('[Upload] $clientFileId 上传失败: $error', stackTrace);
      return UploadFileResult(
        clientFileId: clientFileId,
        isSuccess: false,
        errorCode: CancelToken.isCancel(error) ? 'CANCELLED' : 'NETWORK_ERROR',
      );
    } finally {
      if (identical(_activeCancels[clientFileId], cancelToken)) {
        _activeCancels.remove(clientFileId);
      }
    }
  }

  @override
  void cancelUpload(String clientFileId) {
    _activeCancels.remove(clientFileId)?.cancel('cancelled by user');
  }

  static int? _readInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());
}
