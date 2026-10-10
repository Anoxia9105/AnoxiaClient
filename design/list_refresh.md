# 会话与联系人列表刷新

## 行为与样式

- 手机端保留下拉刷新。刷新圆盘使用 `surfaceContainerHigh` 实色底、主题色进度环和轻阴影，适配浅色/深色及强调色；不再使用透明的 `scaffoldBackgroundColor`。
- 联系人页原本已包裹 RefreshIndicator，但非空字母列表缺少 AlwaysScrollableScrollPhysics，少量联系人时拉不动。字母列表和错误态现在都可滚动触发刷新，空态保留同样能力，字母索引不变。
- 原生桌面端以及宽屏 Web 在两页标题栏提供「刷新列表」IconButton。刷新时禁用按钮并显示等尺寸进度环，避免布局跳动；窄屏 Web 继续使用下拉操作。
- 每个页面的下拉、标题栏按钮、空态刷新和失败重试共用正在执行的 Future，重复操作等待同一轮刷新，不重复请求。
- 继续调用原有会话/联系人刷新服务；保留原来的缓存、刷新失败提示和重试逻辑，不改变同步协议或实时更新机制。

## 验证

```powershell
../AnoxiaProtocol/tool_generate_dart.ps1
flutter test --no-pub test/features/app/list_refresh_test.dart
flutter test --no-pub
flutter analyze --no-pub
```

2026-10-10：7 项定向回归通过；全量 260 项通过、1 项跳过。定向回归覆盖浅色/深色圆盘、联系人少量/空/错误状态下拉刷新，以及两页桌面按钮的等待、恢复和重复请求防护。通过 Flutter 渲染截图检查手机与桌面布局；测试使用隔离数据，不代表真实服务端同步验证。
