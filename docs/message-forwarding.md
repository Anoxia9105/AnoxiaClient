# 消息转发客户端

消息菜单提供转发和多选；多选操作条支持逐条转发、合并转发和取消，最多选择同房 50 条。目标会话选择器支持搜索和加载/错误/空状态，过滤官方、AI 和不可发送房间。

Repository 是 HTTP 与每账号待确认请求的边界；Riverpod forwarding controller 管理提交、状态轮询和恢复，selection family 管理当前房间选择。离房清空选择，撤回/删除移除对应项，账号切换统一失效控制器。

普通气泡显示已转发标记；合并卡片打开分页快照详情，仅复用内容渲染，不复用源消息操作菜单。所有项 seq 确认后同步目标消息、切换会话并定位首项。宽屏切 active，窄屏 push 目标详情并在返回时恢复源会话；用户已离开源会话时旧请求不抢导航。

网络结果未知保留 SharedPreferences 的 `forward_pending_<userId>`。重试沿用 requestId；不同请求先提示恢复旧操作。明确 4xx 拒绝清理未创建请求；部分失败保留请求等待恢复。不使用普通消息 SQLite 发送队列。

服务端契约与迁移见 `AnoxiaServer/docs/Message-Forwarding.md`。直接运行 Flutter 前先生成 AnoxiaProtocol 6.1.0 Dart 代码。

验证：`flutter test`、`flutter analyze --no-fatal-infos`，重点测试为 `test/framework/forward*_test.dart`。实际宽窄屏、附件、目标权限变化与服务器重启还需联调验收。
