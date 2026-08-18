import 'package:flutter_riverpod/legacy.dart' show StateProvider;

/// 打开笔记请求（跨页面深链：聊天卡片「打开笔记」→ 记事本侧栏）。
///
/// 桌面端记事本常驻 IndexedStack，无法通过构造函数传参，
/// 外部入口写入该 Provider，记事本页监听后打开对应笔记。
final noteOpenRequestProvider = StateProvider<int?>((ref) => null);
