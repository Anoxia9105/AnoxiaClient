# Anoxia IM (Flutter Client)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Riverpod-55B5FF?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)

`Anoxia IM` 是一个基于 Flutter 的跨平台即时通讯客户端，支持聊天、联系人、富文本输入、桌面增强能力与音视频通话场景。

> 这是客户端仓库目录 `AnoxiaClient` 的说明文档（可独立开发与运行）。

**仓库地址：** https://gitee.com/crazydavet/AnoxiaClient.git

**在线访问：** https://gitee.com/crazydavet/AnoxiaClient

**官网地址：** https://www.anoxia.cn/

---

## ✨ 核心能力

- 💬 **即时消息**：会话列表、消息状态、系统消息、搜索与常用交互
- 👥 **联系人与关系链**：联系人检索、申请处理、好友与群相关操作
- 📝 **富文本输入**：基于 `flutter_quill` 的编辑与展示能力
- 🎙️ **实时音视频**：`livekit_client` + `flutter_webrtc`
- 🖥️ **桌面体验增强**：托盘、窗口管理、多窗口能力
- 🌍 **国际化与主题**：多语言支持、设置中心、版本检查与反馈入口

---

## 🧱 技术栈

| 方向 | 选型 |
| :-- | :-- |
| 跨平台框架 | Flutter |
| 语言 | Dart |
| 状态管理 | `flutter_riverpod` / `riverpod_generator` |
| 路由 | `go_router` |
| 网络 | `dio` / `web_socket_channel` |
| 音视频 | `livekit_client` / `flutter_webrtc` |
| 本地存储 | `shared_preferences` / `flutter_secure_storage` / `drift`(SQLite) |
| 富文本 | `flutter_quill` |
| IM 协议 | V6 protobuf（`AnoxiaProtocol` 生成的 `anoxia_protocol` 包） |

---

## 📡 消息链路（V6 协议）

- **传输**：WebSocket 二进制帧负载直接是 `ClientFrame`/`ServerFrame` protobuf（无应用层帧头，无版本探测）。路径 `ws://host:8081/chat?token=`，保活走 RFC 6455 Ping/Pong。
- **编解码**：`ImPacketV6`（`lib/framework/codec/v6/im_packet_v6.dart`）在生成的 `anoxia_protocol` 包与本地领域模型间转换；线上无手写 codec。
- **发送**：`SendMessageCommand` 的 `client_message_id` 必须与 `ClientFrame.request_id` 相同；服务端以它为幂等键（24h 去重，DB 唯一索引兜底）。
- **ACK**：关联键是 `ClientFrame.request_id`；先收"入队 ACK"（无 seq），再收下行 `ServerFrame.message` 与携带 `message_id/seq` 的二次 ACK，按 `clientMessageId` 幂等合并（`ws_controller.dart`）。
- **重连**：断线后基于 Drift 本地状态按 `SENDING`/`FAILED` 待确认队列重发，**复用原 `clientMsgId`** 保证服务端去重幂等（见 `AGENTS.md` 消息同步不变量）。未确认超时 15s，自动重试上限 3 次，待确认上限 500。
- **本地持久化**：收到下行消息落 `drift`（`Drift`），撤回/删除经 `MessageOperationEvent` 本地同步移除/标记。
- 协议定义与字段见相邻仓库 `../AnoxiaProtocol`（`proto/anoxia/im/v6/im.proto`）。

---

## 📁 目录结构（精简）

```text
AnoxiaClient/
  lib/
    main.dart           # 入口
    app.dart            # App 根组件
    common/             # 通用工具、常量、基础组件
    framework/          # 网络、模型、主题、provider
    features/           # 业务分层模块
    gen/                # 生成代码
    oss_licenses.dart   # 三方开源许可证信息（生成）
  assets/
    i18n/               # 多语言资源
    images/             # 图片资源
    fonts/              # 字体资源
  test/                 # 测试
```

---

## 🚀 快速开始

### 1) 克隆并进入客户端目录

```bash
git clone https://gitee.com/crazydavet/AnoxiaClient.git
cd AnoxiaClient
```

### 2) 安装依赖

```bash
flutter pub get
```

### 3) 生成代码（Riverpod/路由等）

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4) 生成开源许可证清单（可选）

```bash
dart run flutter_oss_licenses:generate
```

### 5) 运行应用

```bash
flutter run
```

---

## 🧪 开发常用命令

```bash
flutter analyze
flutter test
dart run build_runner watch --delete-conflicting-outputs
```

---

## 🖥️ 平台支持

- Mobile：Android / iOS
- Desktop：Windows / macOS / Linux
- Web：可按 Flutter Web 方式构建（视业务能力启用）

---

## 🤝 贡献指南

欢迎提交 Issue / PR。

提交前建议执行：

1. `flutter analyze`
2. `flutter test`
3. `dart run build_runner build --delete-conflicting-outputs`

你也可以直接通过以下入口参与：

- 官网: https://www.anoxia.cn/
- Issues: https://gitee.com/crazydavet/AnoxiaClient/issues
- Pull Requests: https://gitee.com/crazydavet/AnoxiaClient/pulls

---

## 📄 License

本项目基于 **MIT License** 开源发布。

许可证全文见：[`LICENSE`](./LICENSE)

如已集成许可证生成能力，应用内可在“关于与支持”中查看第三方开源许可证。
