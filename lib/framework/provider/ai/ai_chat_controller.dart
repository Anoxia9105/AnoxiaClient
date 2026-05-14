import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/AiChatMessage.dart';

part 'ai_chat_controller.g.dart';

/// AI 对话控制器
///
/// 管理 AI 聊天的消息列表和请求状态。
/// 支持发送用户消息并获取 AI 回复。
@riverpod
class AiChatController extends _$AiChatController {
  /// 是否正在等待 AI 回复
  bool _loading = false;

  @override
  List<AiChatMessage> build() {
    return [];
  }

  bool get isLoading => _loading;

  /// 向 AI 发送消息并获取回复
  ///
  /// [prompt] 用户输入的文本
  ///
  /// 处理流程：
  /// 1. 先将用户消息插入列表（即时反馈）
  /// 2. 插入占位 AI 消息用于显示 loading
  /// 3. 等待 AI 回复并更新消息内容
  /// 4. 异常时显示友好提示
  Future<void> askGemini(String prompt) async {
    if (prompt.trim().isEmpty || _loading) return;

    _loading = true;

    // 1. 先把用户消息插入列表（即时反馈）
    state = [...state, AiChatMessage(content: prompt, isAi: false)];

    // 2. 插入一个"占位 AI 消息"（用于 loading）
    final aiIndex = state.length;
    state = [...state, AiChatMessage(content: '...', isAi: true)];

    try {
      final resp = await DioClient().post(
        API.chatGemini,
        data: {'prompt': prompt},
      );

      if (resp.data['code'] != 200) {
        throw Exception(resp.data['msg'] ?? 'AI 请求失败');
      }

      final String aiText = resp.data['data']['text'] ?? '';

      // 3. 更新 AI 消息内容
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == aiIndex) state[i].copyWith(content: aiText) else state[i],
      ];
    } catch (e) {
      // 4. 失败兜底（业务友好）
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == aiIndex)
            state[i].copyWith(content: '⚠️ AI 服务暂不可用')
          else
            state[i],
      ];
    } finally {
      _loading = false;
    }
  }
}
