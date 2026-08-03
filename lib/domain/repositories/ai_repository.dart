/// AI 对话仓库抽象接口
///
/// 定义 AI 聊天相关的远程数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class AiRepository {
  /// 向 AI 发送消息并获取回复文本
  ///
  /// [prompt] 用户输入的文本
  ///
  /// 请求失败时抛出异常。
  Future<String> ask(String prompt);
}
