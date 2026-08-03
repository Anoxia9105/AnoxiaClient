import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/ai_repository.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// AI 对话仓库实现
///
/// 通过远程数据源（HTTP API）提供 AI 对话操作。
/// 实现 [AiRepository] 抽象接口，供 UI 层 Provider 使用。
class AiRepositoryImpl implements AiRepository {
  @override
  Future<String> ask(String prompt) async {
    final resp = await DioClient().post(
      API.chatGemini,
      data: {'prompt': prompt},
    );

    if (resp.data['code'] != 200) {
      throw Exception(resp.data['msg'] ?? 'AI 请求失败');
    }

    return resp.data['data']['text'] ?? '';
  }
}
