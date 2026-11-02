# 聊天气泡文字选择

## 交互与实现

- 桌面端：普通文字和 Quill 正文均可鼠标拖选。Ctrl/Cmd+C 复制选区，右键消息菜单的「复制」优先复制打开菜单前的选区，没有选区时复制整条正文。
- 手机端：长按仍打开消息菜单，点击「选择文字」进入单条消息的选择状态，默认全选，可拖动手柄调整范围并复制。
- 选择其它消息、点击聊天空白或输入框时清除旧选区；切换房间时销毁房间的选择协调状态。
- `MessageSelectionScope` 放在聊天页面，保存当前消息的局部 handle。每条消息保留自己的 QuillController/Document；不共享控制器，也不维护进程级气泡 State 集合。
- `MessageSelectionTarget` 连接消息菜单和渲染器；原始指针沿子节点到祖先传播时认领当前消息，页面 scope 只在未认领的点击上退出选择。选择手柄和复制工具栏位于 Overlay，不会被页面 Listener 当作空白点击。
- 普通文字与 WASM 自绘 Delta 使用 `SelectableMessageBody` / Flutter `SelectionArea`，不更改已有富文本渲染路径。
- 自己发送的气泡使用正文前景色生成半透明选区色，Quill 继承气泡的 `DefaultSelectionStyle`。不能再用 `primary` 叠加到本身就是 `primary` 的气泡上，否则高亮与背景完全相同。
- 代码类型消息支持相同的「选择文字 / 复制」入口。代码正文用单个 Text 保留空行、缩进，选择区域置于横向 ScrollView 内部，让鼠标拖选先于滚动参与手势裁决；手机未进入选择时仍可横向滑动。代码面板使用与中性背景匹配的独立选区色。

## Quill 11.5.1 的注意事项

1. 清理旧选区时暂设 `ignoreFocusOnTextChange=true`，防止 Web 内部 `requestKeyboard()` 抢焦点；此标志也跳过部分重绘，所以清理后必须刷新只读视图，不能只断言 Controller 已经 collapsed。
2. 长按开始时弹出消息菜单会取消原手势，Quill 可能收不到 long-press end。转交菜单前清除 `dragOffsetNotifier`，否则旧放大镜状态会让之后的复制工具栏一直为空。
3. 不动态撤掉工具栏 builder：Quill 的 selection overlay 会缓存它。始终提供 builder，按选择状态决定内容。
4. Quill 手柄浮层不属于编辑器的 `TextFieldTapRegion`，气泡关闭 `onTapOutsideEnabled`，由页面 scope 管理退出，否则点击手柄可能先清空选区。
5. Quill 的 `showToolbar()` 在 Web 直接返回 false，JS Web 选择状态提供显式「复制 / 完成」按钮。WASM 路径继续使用 Flutter SelectionArea 的工具栏。

## 验证

```powershell
../AnoxiaProtocol/tool_generate_dart.ps1
flutter test test/features/chat/message_text_selection_test.dart test/features/chat/message_selection_integration_test.dart test/features/chat/failed_message_menu_test.dart
flutter test
flutter analyze
flutter run -d windows -t test/manual/message_selection_smoke.dart
```

离线验收入口使用真实消息菜单与渲染器，但不登录、不连接消息服务、不发送消息。
检查两条富文本依次拖选、与普通文字切换、复制片段、点击空白/输入框、手机长按进入选择及手柄调整。

首次修复验证：全量 676 项通过、2 项跳过；针对性回归 11 项通过；Windows 离线入口构建运行并验证拖选、切换高亮和输入框退出。Android/iOS 手势、手柄及复制使用 widget 测试覆盖；本次 Android 模拟器启动无响应，未完成移动实机验收。

后续配色及代码消息修复：16 项选择回归通过，包含三种主题种子色在深浅模式下的选区背景对比、代码鼠标选择、手机菜单全选复制（保留空行和缩进）、窄屏长代码选择与触摸横向滚动。最终全量 687 项通过、2 项跳过。静态分析无新增问题，仅剩原有 5 条提示。

当前 Flutter 3.47.6 在 Windows 的 `flutter test --platform chrome` 中，CanvasKit 请求返回 404：SDK 的 `_localCanvasKitHandler` 将 URI 转换成 Windows 路径后仍用 `canvaskit/` 前缀判断。未修改 SDK 或产品代码绕过此测试基础设施问题；浏览器可用离线入口另行验收。
