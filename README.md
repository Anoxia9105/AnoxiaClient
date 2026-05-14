# Anoxia IM

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-55B5FF?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Anoxia IM 是一个基于 Flutter 的跨平台即时通讯客户端，支持聊天、联系人、收藏、音视频通话、桌面多窗口与富文本输入。

---

## ✨ 功能概览

- 💬 即时消息：房间会话、消息搜索、系统事件、消息状态管理
- 🎙️ 音视频通话：基于 LiveKit / WebRTC 的实时通话能力
- 🖥️ 桌面增强：托盘、窗口控制、多窗口通话页
- 📝 富文本输入：Flutter Quill + 自定义消息渲染策略
- � 联系人与群组：检索、申请、好友关系与成员管理
- ⚙️ 设置中心：主题、语言、版本更新检查、用户反馈、开源许可查看

---

## 🧱 技术栈

| 方向 | 技术 |
| :-- | :-- |
| UI 与跨平台 | Flutter 3.x |
| 语言 | Dart 3.x |
| 状态管理 | flutter_riverpod + riverpod_generator |
| 路由 | go_router |
| 网络通信 | dio + WebSocket |
| 音视频 | livekit_client + flutter_webrtc |
| 本地存储 | shared_preferences / flutter_secure_storage / sqflite |
| 富文本 | flutter_quill |

---

## � 项目结构（当前）

```text
lib/
  main.dart                 # 入口（主窗口/子窗口/更新窗口启动逻辑）
  app.dart                  # App 根组件
  common/                   # 通用常量、工具、基础组件
  framework/                # 领域模型、网络层、provider、协议与主题
  pages/                    # 业务页面（chat/contact/me/update 等）
  features/                 # 新分层模块（已接入 settings）
    settings/
      application/          # 页面状态编排（Riverpod）
      presentation/
        pages/
        widgets/
  oss_licenses.dart         # 生成的开源许可证数据
```

> 说明：仓库当前处于“渐进式重构”阶段，`features/` 会逐步承接 `pages/` 的页面逻辑，避免一次性迁移带来的功能风险。

---

## 🚀 快速开始

### 1) 获取代码

```bash
git clone https://github.com/<your-account>/Anoxia-IM.git
cd Anoxia-IM/NotePadClient
```

### 2) 安装依赖

```bash
flutter pub get
```

### 3) 生成代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4) （可选）生成开源许可证数据

```bash
dart run flutter_oss_licenses:generate
```

### 5) 运行

```bash
flutter run
```

---

## 🧪 常用开发命令

```bash
flutter analyze
flutter test
dart run build_runner watch --delete-conflicting-outputs
```

---

## � 开源许可

- 本项目使用 **MIT License**。
- App 内可通过：`设置 -> 关于与支持 -> 开源许可` 查看第三方依赖许可证。
