# Anoxia IM (Flutter Client)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Riverpod-55B5FF?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)

`Anoxia IM` 是一个基于 Flutter 的跨平台即时通讯客户端，支持聊天、联系人、富文本输入、桌面增强能力与音视频通话场景。

> 这是客户端仓库目录 `NotePadClient` 的说明文档（可独立开发与运行）。

**仓库地址：** https://github.com/zhang52514/NotePadClient.git

**在线访问：** https://github.com/zhang52514/NotePadClient

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
| 本地存储 | `shared_preferences` / `flutter_secure_storage` |
| 富文本 | `flutter_quill` |

---

## 📁 目录结构（精简）

```text
NotePadClient/
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
git clone https://github.com/zhang52514/NotePadClient.git
cd NotePadClient
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
- Issue: https://github.com/zhang52514/NotePadClient/issues
- Pull Requests: https://github.com/zhang52514/NotePadClient/pulls

---

## 📄 License

本项目基于 **MIT License** 开源发布。

许可证全文见：[`LICENSE`](./LICENSE)

如已集成许可证生成能力，应用内可在“关于与支持”中查看第三方开源许可证。
