# Web Quill 输入法候选窗定位

Flutter Quill 把文档的纯文本交给 Web 引擎的隐藏 textarea；实际富文本仍由
Flutter 绘制。标题、段间距、列表及嵌入块使两边排版不同。当前 Flutter
3.47.6 Web 引擎的 `TextInputSetCaretRect` 是空操作，单独调用
`bringIntoView` 或 `setCaretRect` 无法校正浏览器用于定位输入法的光标。

`QuillWebImeAnchor` 统一用于聊天输入区和记事本。只有编辑器获焦时才运行：

- 从 Quill 的 RenderEditor 读取布局完成后的光标矩形；祖先变换包含内外层滚动。
- 只绑定当前激活且纯文本匹配的 Flutter textarea，不接管普通输入连接。
- 用不可见的纯文本镜像测量 textarea 的原生选区位置，补偿换行、字体和内部滚动。
- 通过独立 CSS `translate` 对齐两边光标下缘，保留引擎自己的 `transform`。
- 不改写 textarea 的文本、选区或组合状态，不重建输入连接；失焦/销毁时移除镜像并恢复样式。
- 获焦期间为当前 Flutter view 设置 `overflow: clip`，隔离整篇 textarea 的滚动溢出；
  测量镜像使用零高度和严格包含，防止参与页面溢出。失焦时恢复原有 view 样式。
- 原生端使用空实现；Web 条件导入基于 `dart.library.js_interop`，兼容 JS/Wasm。

这是对现有引擎 textarea 实现的适配，依赖 `flt-text-editing-host` 和
`flt-text-editing`。升级 Flutter 后需要复测。当前应用没有旋转或倾斜编辑区；
本适配没有支持这种变换。页面缩放、字体加载和真实系统输入法需一起验收。

自动化测试：

```sh
flutter test --platform chrome test/quill_web_ime_binding_test.dart
```

覆盖标题高度变化、引擎更新 transform 后的定位、重复同步不漂移、不修改文本/选区、
样式恢复及输入连接隔离。这些测试验证浏览器中的定位补偿，不代替真实输入法测试。
本机 Windows Flutter 测试服务器曾将 CanvasKit 请求返回 404，使用临时
`test/canvaskit` 目录链接指向 SDK 的 CanvasKit 资源后才能启动；该链接不应提交。

隔离验收页（无需登录，可切换 Fix ON/OFF）：

```sh
flutter run -d chrome --target test/manual/quill_web_ime_probe.dart
```

增加 `--dart-define=IME_PROBE_AUTORUN=true` 会自动检查标题高度变化、滚动和焦点切换，
结果写入页面 `data-quill-ime-probe-results` 并输出调试日志；默认关闭自动操作，方便手动输入。
2026-11-06 在独立 Flutter Web release 页面运行相同检查，四组光标横纵坐标误差均为 0，
切换普通输入框后旧样式和镜像均正确清理。修复组件的 JS/Wasm 隔离构建通过。
新增 Chrome 测试（含滚动回归）3 项通过，修改文件静态分析通过。首轮客户端全量测试 808 项通过、
3 项跳过、4 项失败；4 项分别涉及会话首次加载、失败消息菜单和 AI 菜单，
在未应用本修复的独立 HEAD 基线中同样复现。

## 连续 Shift+Enter 导致底部空白的回归

原补偿移动了保留整篇文档高度的透明 textarea，却未限制其溢出范围。
`html/body` 的 `overflow: hidden` 仍允许 Chromium 为键盘输入的光标自动滚动，
从而滚动固定 body 中的 Flutter view，露出底部背景。不是 Flutter 编辑区本身的滚动。

真实 Chrome 页面连续输入 120 次 Shift+Enter：修复前 `body.scrollTop=193`、
Flutter view 顶部为 `-193px`；修复后两者均保持 `0`，并正常增加 120 个换行。
新增浏览器回归测试覆盖外层程序化滚动和连续换行，同时保留原光标对齐检查。
本轮按用户要求以 Chrome 为验收范围，未继续验证 Edge。

真实验收：Windows 微软拼音，Chrome/Edge，JS/Wasm 各一轮；分别检查聊天和记事本的
空文档、行中插入、自动换行、标题/列表/图片后的文字、内外层滚动及窗口缩放。
输入拼音、选词、取消组合、替换选区应无重复或丢字，切到普通输入框后定位正常。
本轮 Windows 自动化因无法可靠确认浏览器 URL 停止；用户随后在验收页确认开启
Fix ON 后候选框位置正常。尚未完成上述全部浏览器、构建模式和输入场景的交叉验收。

源码依据：

- [Flutter Web 输入实现](https://github.com/flutter/flutter/blob/3.47.6/engine/src/flutter/lib/web_ui/lib/src/engine/text_editing/text_editing.dart)
- [CSS translate 独立于 transform](https://developer.mozilla.org/en-US/docs/Web/CSS/translate)
