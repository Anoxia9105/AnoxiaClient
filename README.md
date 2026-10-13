# Anoxia IM

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Riverpod-55B5FF?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)

Anoxia 是一款基于 Flutter 的跨平台即时通讯应用，将单聊与群聊、音视频通话、AI 助手、富文本记事本和个人日程整合在一起。支持移动端、桌面端与浏览器，并提供中文、英文、日文界面。

[官方网站](https://www.anoxia.cn/) · [在线体验](https://chat.anoxia.cn/) · [GitHub 官方仓库](https://github.com/Anoxia9105/AnoxiaClient) · [问题反馈](https://github.com/Anoxia9105/AnoxiaClient/issues)

## 功能一览

### 即时通讯

- **单聊与群聊**：会话列表、历史消息、未读提示、会话搜索、消息搜索与上下文定位。
- **多种消息内容**：文本、富文本、图片、语音、视频、文件、表情、位置、名片及代码消息；支持对应内容的预览与交互。
- **消息操作**：回复引用、复制、撤回、删除、收藏、多选，以及逐条转发和合并转发；合并记录可展开查看。
- **输入与附件**：富文本编辑、表情选择、群聊 @ 提及、移动端录音与拍摄，以及桌面文件拖放、图片粘贴。
- **本地缓存与同步**：使用 SQLite 缓存会话和消息，支持历史记录加载、断线重连与待发送消息重试。
- **聊天关键词特效**：中英日生日祝福和想念消息触发下落表情；支持本设备开关，并遵循减少动效设置。

### 联系人与群管理

- **好友关系**：搜索用户、发送与处理好友申请、联系人索引、备注和个人资料查看。
- **二维码入口**：个人名片、群二维码、扫码加好友与扫码入群。
- **群管理**：创建群聊、设置群名称与头像、发布群公告、查看和管理成员、入群申请审批、禁言、退出与解散群聊。
- **收藏管理**：集中查看和管理收藏内容，保留消息的类型与预览信息。

### 音视频通话

- 基于 LiveKit 与 WebRTC 提供语音、视频通话和成员邀请。
- 支持麦克风与摄像头控制、媒体设备选择、屏幕共享、参与者视图与通话反应。
- 提供视频与屏幕共享质量设置、连接状态提示和通话诊断信息。
- 桌面端支持独立通话窗口；移动端使用适配小屏的通话布局。

### AI 助手

- **流式对话**：逐步展示 AI 回复，支持多轮会话和 Markdown 内容展示。
- **聊天辅助**：在聊天输入场景中使用 AI 面板辅助组织内容。
- **笔记辅助**：摘要、润色、扩写、标题生成、翻译、续写和自定义指令。
- **结果预览与应用**：先预览笔记 AI 结果，再选择替换或插入内容。

AI 服务由后端配置和管理；未启用或不可用时，客户端会按服务状态调整相关入口。

### 富文本记事本

- 文件夹与笔记树、笔记置顶、移动和排序、标签管理，以及标题与正文搜索。
- 基于 Quill 的富文本编辑，支持标题、列表、引用、链接与图片等内容。
- 自动保存、版本历史与版本还原；删除的笔记可在回收站恢复或彻底删除。
- Markdown 导入与导出、PDF 导出，以及将笔记分享为聊天卡片。
- 桌面侧栏与移动端面板分别适配笔记浏览、编辑和 AI 操作。

### 我的日程

- 日、周、月和议程四种视图，支持今天定位、周期切换和全天日程。
- 新建、编辑和删除日程，设置标题、时间、地点、自定义颜色与提醒。
- 日/周视图支持拖动普通日程改期、调整时长，并在保存失败时恢复原状态。
- 支持每天、每周、每月重复规则，设置间隔、星期和结束条件；编辑与删除重复日程作用于整个系列。
- 支持到期提醒和系统通知。Web 提醒需要应用保持打开，并获得浏览器通知权限。

### 账号与个性化

- 账号密码登录、邮箱验证注册、找回密码、扫码登录、快捷登录和账号切换。
- 访客体验入口由服务端开关控制；Web/桌面 Google 登录需要先完成 OAuth 配置。
- 个人资料、头像和密码管理，中文/英文/日文切换、明暗主题与背景设置。
- 系统公告、问题反馈、版本检查，以及支持平台上的安装包下载与更新。
- 桌面系统托盘、窗口管理和快捷键；开机自启目前仅在 Windows 正式包中开放。

## 平台支持

| 平台 | 说明 |
| --- | --- |
| Android / iOS | 移动端布局、录音与拍摄、扫码、通知及音视频能力；依赖设备权限与原生配置 |
| Windows | 桌面布局、系统托盘、独立通话窗口；正式包支持开机自启 |
| macOS / Linux | 提供桌面构建目标，系统集成能力取决于平台实现与权限 |
| Web | 支持 JavaScript 与 WebAssembly 构建，使用浏览器权限和运行时接口配置 |

平台原生插件通过适配层隔离。相机、屏幕共享、推送、通知等能力以目标平台、浏览器及部署配置为准。

## 技术栈

| 方向 | 选型 |
| --- | --- |
| 跨平台界面 | Flutter、Dart，Dart SDK 要求见 [pubspec.yaml](./pubspec.yaml) |
| 状态管理与路由 | Riverpod 3、go_router，配合代码生成 |
| 网络与实时通信 | Dio、WebSocket、V6 Protobuf |
| 本地数据 | Drift / SQLite、SharedPreferences、Flutter Secure Storage |
| 富文本与内容展示 | Flutter Quill、Markdown、图片/音视频预览 |
| 实时音视频 | LiveKit、flutter_webrtc |
| 国际化 | easy_localization，中文 / 英文 / 日文 |
| 系统集成 | 通知、推送、托盘、多窗口与平台适配层 |

## 本地开发

### 1. 准备环境与协议项目

安装 Flutter stable、满足 [pubspec.yaml](./pubspec.yaml) 要求的 Dart SDK、Git、`protoc`，以及目标平台需要的构建工具。先执行 `flutter doctor` 检查环境。

客户端依赖独立的 `AnoxiaProtocol` 项目生成 Dart 协议包，两个项目必须放在同一父目录下：客户端使用 `../AnoxiaProtocol/gen/dart` 作为 path 依赖。仅克隆客户端无法完成依赖安装。

```bash
git clone https://github.com/Anoxia9105/AnoxiaClient.git
cd AnoxiaClient
```

准备好同级 `AnoxiaProtocol` 后，安装 Dart 生成插件并生成协议：

```powershell
dart pub global activate protoc_plugin 25.0.0
../AnoxiaProtocol/tool_generate_dart.ps1
```

macOS / Linux 使用：

```bash
dart pub global activate protoc_plugin 25.0.0
bash ../AnoxiaProtocol/tool_generate_dart.sh
```

工具路径与协议生成说明见 `../AnoxiaProtocol/README.md`。每次修改协议后，都应重新生成；`flutter pub get` 不会替你刷新协议代码。

### 2. 安装依赖与生成代码

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

修改 Riverpod、Drift 数据表或生成式路由后，需要重新运行代码生成，并保留相应的 `*.g.dart` 产物。

### 3. 配置连接地址

- **Android / iOS / 桌面端**：默认连接正式服务器。自托管或本地联调时，修改 [runtime_config_io.dart](./lib/platform/shims/runtime_config_io.dart) 中的 HTTP、WebSocket、LiveKit 与二维码地址。
- **Web**：通过 [web/runtime-config.js](./web/runtime-config.js) 中的 `window.__ANOXIA_CONFIG__` 注入部署地址；未注入时按当前站点推断。HTTP、聊天 WebSocket、音视频与二维码地址可以分别配置。
- **Google 登录**：客户端使用 `GOOGLE_OAUTH_CLIENT_ID`；Web 也支持运行时 `googleClientId`。服务端需配置对应 OAuth 凭据及重定向地址。

自建服务端的环境变量与部署要求见服务端 README 和部署文档。

### 4. 启动

```bash
flutter run -d windows
flutter run -d chrome
```

也可运行 `flutter devices` 查看可用目标，再使用 `flutter run -d <device-id>` 启动。

## 构建与验证

优先使用项目根目录构建脚本。脚本依次生成 Dart 协议、安装依赖、运行协议 wire 回归测试，再执行目标平台构建。

```powershell
./tool_build.ps1 -Target web
./tool_build.ps1 -Target web -Wasm
./tool_build.ps1 -Target android
./tool_build.ps1 -Target windows
```

Windows 也可使用同参数的 `tool_build.bat`；macOS / Linux 使用 `bash tool_build.sh -Target web -Wasm` 等对应命令。各平台原生构建需要在具备相应工具链的系统中执行。

| 命令 | 用途 |
| --- | --- |
| `flutter analyze` | 静态分析 |
| `flutter test` | 运行测试 |
| `flutter test test/framework/codec/im_packet_v6_test.dart` | V6 wire 兼容性回归 |
| `dart run build_runner watch --delete-conflicting-outputs` | 开发时持续生成代码 |
| `dart run flutter_oss_licenses:generate` | 刷新第三方许可证清单 |

直接执行 `flutter run`、`flutter test` 或 `flutter build` 前，应确保同级协议项目的 Dart 代码已经生成。

## 更多文档

| 文档 | 内容 |
| --- | --- |
| [架构与开发说明](./code_wiki.md) | 客户端模块、协议与核心流程 |
| [消息转发](./docs/message-forwarding.md) | 逐条转发、合并转发与验证说明 |
| [日程功能与接口](./docs/schedule_v2_spec.md) | 日历视图、拖拽、提醒、重复规则与部署 |
| [日历界面设计决策](./docs/decisions/0001-own-schedule-calendar-ui.md) | 日历 UI 的实现选择 |
| [音视频优化](./docs/livekit_optimization.md) | 通话行为、恢复与部署条件 |
| [平台开发说明](./docs/platform-behavior.md) | Android 返回、桌面拖放、移动拍摄与列表刷新 |

## 参与贡献

欢迎通过 [Issues](https://github.com/Anoxia9105/AnoxiaClient/issues) 反馈问题、提出建议，或提交 [Pull Request](https://github.com/Anoxia9105/AnoxiaClient/pulls)。反馈时请附上平台、应用版本、复现步骤及相关日志；提交代码前运行静态分析和测试，涉及生成代码时同步更新产物。

## 开源许可

客户端采用 [MIT License](./LICENSE)。第三方依赖的许可证可在应用“关于与支持”中查看。
