import 'package:talker_flutter/talker_flutter.dart';

/// 全局日志记录器
///
/// 使用 Talker 库进行日志记录，支持历史记录、控制台输出等功能
///
/// 主要功能：
/// - 记录各种级别的日志（info、warning、error 等）
/// - 保存日志历史以便查看
/// - 支持在控制台输出格式化的日志
final log = Talker(
  settings: TalkerSettings(
    /// 启用/禁用日志功能
    enabled: true,
    /// 启用/禁用保存日志历史
    useHistory: true,
    /// 历史记录最大条数
    maxHistoryItems: 100,
    /// 启用/禁用控制台日志输出
    useConsoleLogs: true,
  ),
  /// 日志记录器实现
  logger: TalkerLogger(),
);