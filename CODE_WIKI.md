# Anoxia IM - Code Wiki

## 目录
1. [项目概述](#1-项目概述)
2. [架构设计](#2-架构设计)
3. [主要模块职责](#3-主要模块职责)
4. [核心类与函数说明](#4-核心类与函数说明)
5. [依赖关系](#5-依赖关系)
6. [项目运行方式](#6-项目运行方式)

---

## 1. 项目概述

### 1.1 项目简介
Anoxia IM 是一个基于 Flutter 的跨平台即时通讯解决方案，支持低延迟消息传递和强大的状态同步。该项目支持多种平台，包括：
- Windows/macOS/Linux（桌面端）
- Android/iOS（移动端）
- Web

### 1.2 核心功能
- 💬 实时聊天：房间会话、消息搜索、系统事件管理
- 🎙️ 音视频通话：基于 LiveKit + WebRTC 的实时通话
- 🖥️ 桌面增强：系统托盘、多窗口支持、窗口管理
- 📝 富文本输入：Flutter Quill + 自定义消息渲染策略
- 📱 联系人与群组：搜索、好友请求、成员管理
- ⚙️ 个性化设置：主题切换、多语言支持、版本更新

### 1.3 技术栈
| 类别 | 技术 |
|------|------|
| UI框架 | Flutter 3.x |
| 编程语言 | Dart 3.x |
| 状态管理 | flutter_riverpod + riverpod_generator |
| 路由 | go_router |
| 网络通信 | Dio + WebSocket |
| 音视频 | livekit_client + flutter_webrtc |
| 本地存储 | shared_preferences + flutter_secure_storage |
| 富文本 | flutter_quill |

---

## 2. 架构设计

### 2.1 目录结构
```
lib/
├── main.dart                   # 应用入口（主窗口/子窗口/更新窗口启动逻辑）
├── App.dart                    # App根组件
├── common/                     # 通用模块
│   ├── constants/              # 常量定义
│   │   ├── API.dart
│   │   └── StorageKeys.dart
│   ├── utils/                  # 工具类
│   │   ├── DateUtil.dart
│   │   ├── NotificationHelper.dart
│   │   └── ...
│   └── widgets/                # 通用组件
│       ├── Toast.dart
│       └── ...
├── framework/                  # 核心框架
│   ├── domain/                 # 领域模型
│   ├── network/                # 网络层
│   ├── protocol/               # 协议层
│   ├── provider/               # 状态管理
│   └── theme/                  # 主题
├── features/                   # 新特性模块（Feature First）
│   └── settings/               # 设置功能（已迁移示例）
│       ├── application/        # 状态编排
│       └── presentation/       # 页面与组件
├── pages/                      # 传统页面模块（待迁移）
│   ├── chat/
│   ├── contact/
│   └── ...
└── gen/                        # 生成的代码
```

### 2.2 架构模式
项目正在从传统的页面驱动架构迁移到 **Feature First 架构**，主要特点：
- `features/` 目录按业务功能划分
- 每个功能内部遵循 `application/data/domain/presentation` 分层
- `pages/` 目录保留兼容性导出，逐步迁移

---

## 3. 主要模块职责

### 3.1 common 模块
**职责**：提供跨模块通用的基础能力
- 常量定义：API地址、存储键
- 工具类：日期、通知、设备检测、文件操作
- 通用组件：Toast、骨架屏、弹框等

### 3.2 framework 模块
**职责**：核心框架层，提供基础设施
- **domain**：领域实体定义（User、ChatMessage、Room等）
- **network**：HTTP通信封装（DioClient）、Token管理
- **protocol**：协议解析（消息、事件、高频消息）
- **provider**：Riverpod状态管理（按功能分组）
- **theme**：主题系统

### 3.3 features 模块
**职责**：按业务功能划分的新架构模块
- **settings**：设置功能（已迁移示例）
  - application：设置页控制器
  - presentation：设置页UI组件

### 3.4 pages 模块
**职责**：传统页面（待逐步迁移）
- chat：聊天相关页面
- contact：联系人相关页面
- aichat：AI聊天页面
- setting：设置页（兼容旧路径）

---

## 4. 核心类与函数说明

### 4.1 入口与启动
#### [main.dart](file:///d:/GIT/NotePadClient/lib/main.dart)
- **globalContainer**：全局 Riverpod 容器，所有窗口共享状态
- **_handleDesktopWindows**：处理桌面端窗口（主/子窗口区分）
- **runMainApp**：启动主窗口
- **runSubApp**：启动子窗口（如通话窗口）
- **_checkUpdate**：检查应用更新

#### [App.dart](file:///d:/GIT/NotePadClient/lib/App.dart)
- **_AppState**：根组件状态，管理系统托盘和窗口事件
- **_initTray**：初始化系统托盘菜单
- **onTrayIconMouseDown/RightMouseDown**：托盘点击事件

### 4.2 网络层
#### [DioClient](file:///d:/GIT/NotePadClient/lib/framework/network/DioClient.dart)
- **单例模式**：全局唯一实例
- **请求拦截器**：自动添加 Bearer Token
- **响应拦截器**：统一处理 401 鉴权失败，触发登出
- **核心方法**：
  - `get/post/put/delete`：基础HTTP方法
  - `uploadFile/uploadFiles`：文件上传
  - `download`：文件下载

#### [WsController](file:///d:/GIT/NotePadClient/lib/framework/provider/ws/ws_controller.dart)
- **WebSocket管理**：连接、重连、心跳
- **消息流**：`wsMessageStream` 暴露消息事件总线
- **核心方法**：
  - `connect`：建立连接
  - `sendMessage`：发送消息
  - `_handleIncomingMessage`：处理收到的消息
  - `_retryConnection`：指数退避重连策略（2-30秒）

### 4.3 状态管理
#### 路由 - [router.dart](file:///d:/GIT/NotePadClient/lib/framework/provider/router/router.dart)
- **GoRouter**：类型安全的路由
- **重定向逻辑**：
  - 未初始化 → Splash页
  - 未登录 → Login页
  - 已登录 → Home页
- **核心路由**：
  - `InitLoginRoute`：登录页
  - `HomeRoute`：主页
  - `SplashRoute`：启动页
  - `ErrorRoute`：错误页

#### 认证 - auth_controller
- 管理用户登录状态
- Token刷新与登出逻辑

#### 聊天 - 消息与房间
- `roomMessageServiceProvider`：房间消息服务
- `roomListServiceProvider`：房间列表服务
- `chatInputControllerProvider`：输入框控制器

### 4.4 协议层
#### [PacketType](file:///d:/GIT/NotePadClient/lib/framework/protocol/PacketType.dart)
```dart
enum PacketType {
  message,         // 0 - 普通消息
  highFrequency,   // 1 - 高频消息（如 typing 状态）
  event,           // 2 - 系统事件
  unknown          // 3 - 未知
}
```

#### [PacketRegistry](file:///d:/GIT/NotePadClient/lib/framework/protocol/register/PacketRegistry.dart)
- 协议解析器注册
- 支持动态注册不同类型的消息解析器

---

## 5. 依赖关系

### 5.1 主要依赖
```yaml
# UI 框架
flutter: sdk:flutter
flutter_screenutil: ^5.9.3
hugeicons: ^1.1.5

# 状态管理
flutter_riverpod: ^3.0.3
riverpod_annotation: ^3.0.3

# 路由
go_router: ^17.0.0

# 网络
dio: ^5.9.0
web_socket_channel: ^3.0.3

# 音视频
livekit_client: ^2.6.2
flutter_webrtc: ^1.3.0

# 存储
shared_preferences: ^2.5.3
flutter_secure_storage: ^9.0.0

# 富文本
flutter_quill: ^11.5.0

# 国际化
easy_localization: ^3.0.8

# 日志
talker_flutter: ^5.1.5
talker_riverpod_logger: ^5.1.5
```

### 5.2 模块依赖关系
```
main.dart
├── App.dart
├── framework/provider/ (状态管理)
│   ├── auth/
│   ├── chat/
│   ├── ws/
│   └── router/
├── framework/network/ (网络层)
│   └── DioClient
├── framework/protocol/ (协议层)
└── pages/ + features/ (UI层)
```

---

## 6. 项目运行方式

### 6.1 环境要求
- Flutter SDK >= 3.10.1
- Dart SDK >= 3.10.1

### 6.2 安装与运行

#### 1. 安装依赖
```bash
flutter pub get
```

#### 2. 生成代码
项目使用代码生成（Riverpod、GoRouter、FlutterGen），首次运行需要：
```bash
dart run build_runner build --delete-conflicting-outputs
```

开发时可以使用 watch 模式：
```bash
dart run build_runner watch --delete-conflicting-outputs
```

#### 3. 运行应用
```bash
# 运行默认设备
flutter run

# 运行特定平台
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome
```

### 6.3 常用开发命令
```bash
# 代码分析
flutter analyze

# 运行测试
flutter test

# 生成开源许可证数据
dart run flutter_oss_licenses:generate
```

---

## 7. 开发建议

### 7.1 代码规范
- 单文件超过 300 行 → 必须拆分
- 单文件超过 500 行 → 优先拆分
- 新功能建议使用 `features/` 目录下的 Feature First 架构

### 7.2 迁移计划
下一批建议迁移优先级（按复杂度与收益）：
1. `lib/pages/update/UpdatePage.dart`（543行）
2. `lib/pages/contact/AddFriendPage.dart`（748行）
3. `lib/pages/chat/component/ChatRoomList.dart`（673行）
4. `lib/pages/chat/component/widget/ChatAppBar.dart`（664行）
5. `lib/pages/chat/component/widget/ChatInputField.dart`（615行）

### 7.3 兼容性策略
- 旧路径保留 `export` 导出文件
- 路由与外部 import 逐步迁移，避免一次性大改

---

## 附录
- [项目结构优化方案](file:///d:/GIT/NotePadClient/docs/flutter-code-structure-plan.md)
- [Token 优化说明](file:///d:/GIT/NotePadClient/docs/TOKEN_OPTIMIZATION.md)
