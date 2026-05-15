# Anoxia IM - Code Wiki 文档

## 1. 项目概述

### 1.1 项目简介

**Anoxia IM** 是一个基于 Flutter 3.x 构建的高性能跨平台即时通讯（IM）客户端应用。项目采用 Dart 作为开发语言，支持 Android、iOS、Windows、macOS、Linux 和 Web 等多个平台。

### 1.2 核心功能特性

| 功能模块 | 功能描述 |
|---------|---------|
| 即时消息 | 支持文本、图片、文件、富文本等多类型消息，支持消息撤回、收藏 |
| 音视频通话 | 基于 LiveKit + WebRTC 实现实时音视频通话能力 |
| 联系人管理 | 好友申请、联系人列表、群组管理 |
| 富文本输入 | 基于 Flutter Quill 实现支持 Mention、文件嵌入的富文本编辑器 |
| 多窗口支持 | 桌面端支持多窗口通话页面 |
| 主题系统 | 支持 19 种预设主题（7 种亮色 + 12 种暗色） |
| 多语言支持 | 支持中文、英文、日文三种语言 |

### 1.3 技术栈概览

```
┌─────────────────────────────────────────────────────────┐
│                      UI 层                              │
│  Flutter Widgets + Flutter Quill + 自定义组件            │
├─────────────────────────────────────────────────────────┤
│                    状态管理层                            │
│  flutter_riverpod + riverpod_generator                │
├─────────────────────────────────────────────────────────┤
│                    路由层                                │
│  go_router + go_router_builder                         │
├─────────────────────────────────────────────────────────┤
│                    网络通信层                            │
│  Dio (HTTP) + web_socket_channel (WebSocket)           │
├─────────────────────────────────────────────────────────┤
│                    音视频层                              │
│  livekit_client + flutter_webrtc                       │
├─────────────────────────────────────────────────────────┤
│                    本地存储层                            │
│  shared_preferences + flutter_secure_storage           │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 项目架构

### 2.1 整体架构图

```
┌──────────────────────────────────────────────────────────────────┐
│                           lib/                                   │
│  ┌─────────┬──────────────┬──────────────┬──────────────────┐   │
│  │  main   │     App      │    common    │    framework     │   │
│  │ .dart   │   .dart      │              │                  │   │
│  └─────────┴──────────────┴──────────────┴──────────────────┘   │
│      │         │                │                │               │
│      │         │    ┌───────────┼────────────┐   │               │
│      │         │    │           │            │   │               │
│      │         │    ▼           ▼            ▼   ▼               │
│      │         │ ┌──────┐ ┌────────┐ ┌────────────┐             │
│      │         │ │constants│ │ utils │ │   widgets  │             │
│      │         │ └──────┘ └────────┘ └────────────┘             │
│      │         │                                              │
│      │         │    ┌──────────────────────────────────────┐    │
│      │         │    │            framework/                 │    │
│      │         │    │  ┌─────────┬────────┬────────┬─────┐ │    │
│      │         │    │  │ domain  │network │protocol│theme │ │    │
│      │         │    │  └─────────┴────────┴────────┴─────┘ │    │
│      │         │    │  ┌────────────────────────────────┐  │    │
│      │         │    │  │          provider/              │  │    │
│      │         │    │  │  ┌────┬─────┬──────┬────────┐ │  │    │
│      │         │    │  │  │auth│chat │contact│ setting│ │  │    │
│      │         │    │  │  └────┴─────┴──────┴────────┘ │  │    │
│      │         │    │  └────────────────────────────────┘  │    │
│      │         │    └──────────────────────────────────────┘    │
│      │         │                                              │
│      │         │    ┌──────────────────────────────────────┐    │
│      │         │    │            features/                 │    │
│      │         │    │  ┌─────────┬────────┬─────────┐   │    │
│      │         │    │  │   app   │  chat  │ contact │   │    │
│      │         │    │  └─────────┴────────┴─────────┘   │    │
│      │         │    └──────────────────────────────────────┘    │
└──────┴─────────┴─────────────────────────────────────────────────┘
```

### 2.2 目录结构说明

```
lib/
├── main.dart                    # 应用程序入口文件
├── App.dart                     # 应用根组件
├── gen/                         # 资源生成代码
│   ├── assets.gen.dart          # 静态资源引用
│   └── fonts.gen.dart           # 字体资源引用
│
├── common/                      # 通用模块（工具、常量、基础组件）
│   ├── constants/
│   │   ├── API.dart             # API 接口地址常量
│   │   └── StorageKeys.dart     # 存储键名常量
│   ├── utils/
│   │   ├── DateUtil.dart        # 日期时间工具类
│   │   ├── Debouncer.dart       # 防抖工具类
│   │   ├── DeviceUtil.dart      # 设备平台检测工具
│   │   ├── NotificationHelper.dart  # 通知助手
│   │   ├── PageTransitions.dart # 页面转场动画
│   │   ├── QuillEmbedUtil.dart  # Quill 富文本嵌入工具
│   │   ├── SPUtil.dart          # SharedPreferences 封装
│   │   ├── SSUtil.dart          # SecureStorage 封装
│   │   ├── StringUtil.dart      # 字符串工具类
│   │   ├── Validators.dart      # 数据验证工具
│   │   └── fileUtil.dart        # 文件操作工具类
│   └── widgets/                 # 通用 UI 组件
│       ├── AcrylicContainer.dart
│       ├── AvatarWidget.dart
│       ├── BlurBackground.dart
│       ├── BubbleDialog.dart
│       ├── CustomButton.dart
│       ├── FocusOverlayManager.dart
│       ├── NoData.dart
│       ├── SkeletonBox.dart
│       ├── Toast.dart
│       ├── VibratingBadge.dart
│       ├── Welcome.dart
│       ├── app/                  # 应用级组件
│       │   ├── MobileBottomBar.dart
│       │   └── app_scaffold.dart
│       └── desktop/             # 桌面端组件
│           ├── DesktopAppBar.dart
│           └── DesktopSidebar.dart
│
├── framework/                   # 核心框架层
│   ├── domain/                  # 领域模型
│   │   ├── AiChatMessage.dart
│   │   ├── Attachment.dart
│   │   ├── CaptchaModel.dart
│   │   ├── ChatContactDetailVO.dart
│   │   ├── ChatContactRequestVO.dart
│   │   ├── ChatContactVO.dart
│   │   ├── ChatFavorite.dart
│   │   ├── ChatMessage.dart      # 聊天消息模型
│   │   ├── ChatRoomMemberVO.dart
│   │   ├── ChatRoomVO.dart       # 聊天室视图对象
│   │   ├── ContactRequest.dart
│   │   ├── MessagePayload.dart
│   │   ├── RoomState.dart
│   │   ├── upload_entry.dart
│   │   ├── UserInfo.dart         # 用户信息模型
│   │   ├── UserSearchResponse.dart
│   │   └── UserVO.dart
│   ├── extensions/               # 扩展方法
│   │   ├── QuillCursorX.dart
│   │   └── window_controller.dart
│   ├── logs/                     # 日志系统
│   │   └── talker.dart
│   ├── network/                   # 网络层
│   │   ├── DioClient.dart        # HTTP 客户端封装
│   │   ├── DioConfig.dart        # Dio 配置
│   │   └── TokenManager.dart      # Token 管理器
│   ├── protocol/                  # 协议层
│   │   ├── IPacket.dart           # 数据包接口
│   │   ├── PacketFrame.dart       # 数据包帧
│   │   ├── PacketType.dart        # 消息类型枚举
│   │   ├── message/               # 消息协议
│   │   │   ├── Attachment.dart
│   │   │   ├── EventMessage.dart
│   │   │   ├── HighMessage.dart
│   │   │   ├── MessageEunm.dart
│   │   │   ├── MessagePayload.dart
│   │   │   └── RoomMessage.dart   # 聊天室消息
│   │   └── register/             # 协议注册
│   │       └── PacketRegistry.dart
│   ├── provider/                  # Riverpod 状态管理
│   │   ├── ai/
│   │   ├── auth/
│   │   ├── chat/
│   │   ├── contact/
│   │   ├── core/
│   │   ├── layout/
│   │   ├── router/
│   │   ├── setting/
│   │   ├── theme/
│   │   └── ws/
│   └── theme/                     # 主题系统
│       ├── AppColors.dart
│       ├── AppTheme.dart
│       └── ThemeMixin.dart
│
└── features/                     # 业务功能模块
    ├── app/                       # 应用核心页面
    │   └── presentation/
    │       └── pages/
    │           ├── error_page.dart
    │           ├── login_page.dart
    │           ├── main_layout_page.dart
    │           └── splash_page.dart
    ├── chat/                      # 聊天模块
    │   └── presentation/
    │       ├── call/              # 通话功能
    │       ├── pages/
    │       └── widgets/
    ├── contact/                   # 联系人模块
    │   └── presentation/
    │       ├── pages/
    │       └── widgets/
    ├── favorite/                  # 收藏模块
    │   └── presentation/
    │       └── pages/
    ├── me/                        # 个人中心模块
    │   └── presentation/
    │       ├── pages/
    │       └── widgets/
    ├── settings/                  # 设置模块
    │   └── presentation/
    │       ├── pages/
    │       └── widgets/
    └── update/                    # 更新模块
        └── presentation/
            ├── pages/
            └── widgets/
```

---

## 3. 核心模块详解

### 3.1 入口模块

#### 3.1.1 main.dart

**文件路径**: `lib/main.dart`

**职责描述**: 应用程序的入口点，负责初始化核心资源、检测更新、注册协议解析器、处理桌面端多窗口逻辑。

**关键函数**:

| 函数名 | 返回类型 | 描述 |
|--------|---------|------|
| `main()` | `Future<void>` | 应用主入口，协调初始化流程 |
| `runMainApp()` | `Future<void>` | 启动主窗口，初始化全局状态和桌面窗口配置 |
| `runSubApp()` | `Future<void>` | 启动子窗口（通话窗口），继承全局容器 |
| `runUpdateApp()` | `Future<void>` | 启动更新窗口，显示版本更新信息 |
| `setupDesktopWindow()` | `Future<void>` | 配置桌面窗口尺寸和样式 |
| `_registerPacketParsers()` | `void` | 注册 WebSocket 协议解析器 |
| `_checkUpdate()` | `Future<AppUpdateInfo?>` | 检查应用版本更新 |

**核心初始化流程**:

```dart
main()
  ├── EasyLocalization.ensureInitialized()  // 多语言初始化
  ├── SPUtil.instance.init()                  // 本地存储初始化
  ├── _checkBluetoothPermissions()            // 蓝牙权限申请（Android）
  ├── _checkUpdate()                          // 版本更新检查
  ├── _registerPacketParsers()                // 协议解析器注册
  └── _handleDesktopWindows()                  // 桌面窗口处理
      ├── runMainApp()                        // 主窗口
      └── runSubApp()                         // 子窗口
```

**全局容器**:

```dart
final ProviderContainer globalContainer = ProviderContainer();
```

所有窗口共享同一个 `globalContainer`，实现状态同步。

#### 3.1.2 App.dart

**文件路径**: `lib/App.dart`

**职责描述**: 应用根组件，负责初始化系统事件服务、桌面端托盘/窗口管理、移动端角标监听、主题/多语言配置。

**生命周期管理**:

| 生命周期方法 | 触发时机 | 执行操作 |
|-------------|---------|---------|
| `initState()` | 组件创建 | 启动系统事件服务、初始化托盘、注册窗口监听 |
| `dispose()` | 组件销毁 | 取消订阅、移除监听器 |

**桌面端托盘菜单**:

| 菜单项 | 功能描述 |
|-------|---------|
| `tray_show_window` | 显示并聚焦主窗口 |
| `tray_hide_window` | 隐藏主窗口 |
| `tray_exit` | 退出应用程序 |

---

### 3.2 网络通信模块

#### 3.2.1 DioClient

**文件路径**: `lib/framework/network/DioClient.dart`

**职责描述**: 基于 Dio 封装的 HTTP 客户端，提供统一的 RESTful API 调用能力。支持自动 Token 注入、401 自动登出、文件上传下载等常用功能。

**单例模式**: `DioClient()` 工厂方法返回单例实例。

**核心方法**:

| 方法名 | 返回类型 | 描述 |
|--------|---------|------|
| `get()` | `Future<Response>` | GET 请求 |
| `post()` | `Future<Response>` | POST 请求 |
| `put()` | `Future<Response>` | PUT 请求 |
| `delete()` | `Future<Response>` | DELETE 请求 |
| `uploadFile()` | `Future<Response>` | 单文件上传 |
| `uploadFiles()` | `Future<Response>` | 多文件上传 |
| `download()` | `Future<Response>` | 文件下载 |

**请求拦截器功能**:

- 自动注入 `Authorization: Bearer {token}` 请求头
- 优先从内存缓存获取 Token，减少频繁读取本地存储
- 401 响应自动触发登出并跳转登录页

**使用示例**:

```dart
// GET 请求
final response = await DioClient().get(
  API.chatHistory,
  queryParameters: {"roomId": "xxx", "pageSize": 50},
);

// POST 请求
final response = await DioClient().post(
  API.login,
  data: {"username": "xxx", "password": "xxx"},
  auth: false,  // 登录接口不需要鉴权
);

// 文件上传
final response = await DioClient().uploadFile(
  API.uploadFile,
  file: File('/path/to/file'),
  data: {"roomId": "xxx"},
);
```

#### 3.2.2 TokenManager

**文件路径**: `lib/framework/network/TokenManager.dart`

**职责描述**: 负责 Token 的读取、写入和清除操作。采用内存缓存 + 本地持久化的双层策略，减少 IO 操作。

**核心方法**:

| 方法名 | 返回类型 | 描述 |
|--------|---------|------|
| `getToken()` | `Future<String?>` | 获取 Token，优先返回内存缓存 |
| `setToken()` | `Future<void>` | 保存 Token，同步更新内存，异步写入存储 |
| `clearToken()` | `Future<void>` | 清除 Token，同步清空内存，异步删除存储 |

**存储机制**:

```
┌─────────────────────────────────┐
│         TokenManager           │
│  ┌───────────────────────────┐  │
│  │    内存缓存 (_cachedToken) │  │
│  └───────────────────────────┘  │
│               │                 │
│               ▼                 │
│  ┌───────────────────────────┐  │
│  │   SecureStorage (持久化)   │  │
│  │   key: "access_token"      │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

---

### 3.3 协议层

#### 3.3.1 PacketType

**文件路径**: `lib/framework/protocol/PacketType.dart`

**职责描述**: WebSocket 消息主题枚举，用于区分不同类型的业务消息。

**枚举值**:

| 枚举值 | 描述 | 对应后端类型 |
|-------|------|------------|
| `message` | 普通聊天消息 | MESSAGE |
| `highFrequency` | 高频消息（如输入状态、通话信令） | HIGH_FREQUENCY |
| `event` | 系统事件消息 | EVENT |
| `unknown` | 未知类型（解析失败时的默认值） | - |

**解析方法**: `PacketType.from(dynamic value)`

支持后端传来的数字下标（0, 1, 2...）或字符串名称（"MESSAGE", "EVENT"）。

#### 3.3.2 PacketRegistry

**文件路径**: `lib/framework/protocol/register/PacketRegistry.dart`

**职责描述**: 数据包解析注册表，维护 `PacketType` 到解析器的映射。

**核心方法**:

| 方法名 | 描述 |
|--------|------|
| `register(PacketType type, PacketParser parser)` | 注册解析器 |
| `parse(PacketType type, Map<String, dynamic> data)` | 根据类型解析消息 |

**注册示例**:

```dart
PacketRegistry.register(
  PacketType.message,
  (data) => RoomMessage.fromJson(data),
);
PacketRegistry.register(
  PacketType.event,
  (data) => EventMessage.fromJson(data),
);
```

#### 3.3.3 RoomMessage

**文件路径**: `lib/framework/protocol/message/RoomMessage.dart`

**职责描述**: 通过 WebSocket 传输的完整消息模型，实现 `IPacket` 接口。

**属性说明**:

| 属性名 | 类型 | 描述 |
|-------|------|------|
| `roomId` | `String` | 聊天室 ID |
| `clientMsgId` | `String?` | 客户端生成的消息 ID |
| `messageId` | `String` | 服务器消息 ID |
| `senderId` | `int` | 发送者用户 ID |
| `senderName` | `String` | 发送者昵称 |
| `senderAvatar` | `String` | 发送者头像 |
| `type` | `MessageType` | 消息类型 |
| `payload` | `MessagePayload?` | 消息负载（支持富文本、引用等） |
| `attachments` | `List<Attachment>` | 文件附件列表 |
| `extra` | `Map<String, dynamic>` | 扩展字段 |
| `state` | `MessageState` | 消息状态 |
| `status` | `DeliveryStatus` | 投递状态 |
| `timestamp` | `int` | 时间戳（毫秒） |
| `seq` | `int` | 消息序号（用于排序和去重） |

---

### 3.4 状态管理模块

#### 3.4.1 WsController

**文件路径**: `lib/framework/provider/ws/ws_controller.dart`

**职责描述**: WebSocket 连接控制器，负责连接的建立、心跳维护、自动重连和消息分发。采用 keepAlive 模式，确保全局只有一个连接实例。

**核心功能**:

| 功能 | 描述 |
|-----|------|
| 连接管理 | 建立 WebSocket 连接，支持 Web 和桌面端 |
| 心跳保活 | 每 30 秒发送一次 ping，保持连接活跃 |
| 自动重连 | 指数退避重连策略（2s, 4s, 8s... 最大 30s） |
| 消息分发 | 将接收到的消息通过 Stream 分发给各 Consumer |
| 错误处理 | 解析 ACK 错误码，显示 Toast 提示（2秒内重复错误不重复提示） |

**重连策略**:

```dart
// 重连间隔计算
int delaySeconds = (1 << _reconnectAttempts).clamp(2, 30);
// 第一次：2s，第二次：4s，第三次：8s... 最大 30s
```

**消息流**:

```dart
Stream<PacketFrame<IPacket>> get messageStream => _messageController.stream;
```

外部 Provider 通过监听此 Stream 获取 WebSocket 消息。

#### 3.4.2 AuthController

**文件路径**: `lib/framework/provider/auth/auth_controller.dart`

**职责描述**: 认证状态管理器，负责用户登录、登出和会话恢复。

**核心方法**:

| 方法名 | 返回类型 | 描述 |
|--------|---------|------|
| `build()` | `Future<UserInfo?>` | 自动恢复登录会话 |
| `login()` | `Future<void>` | 用户登录 |
| `logout()` | `Future<void>` | 用户登出 |
| `refreshUserInfo()` | `Future<void>` | 刷新用户信息 |

**登录流程**:

```
login()
  ├── 调用 /login 接口获取 token
  ├── 保存 token 到 TokenManager
  ├── 保存 token 到内存缓存
  ├── 调用 /getInfo 获取用户信息
  └── 重新触发 AppInitializer
```

**登出流程**:

```
logout()
  ├── 调用 /logout 通知后端（异步，不阻塞）
  ├── 清除 TokenManager 中的 token
  ├── 清除内存中的 token 缓存
  ├── 重置认证状态为 null
  └── WsController 自动断开连接
```

#### 3.4.3 ChatMessages (RoomMessageService)

**文件路径**: `lib/framework/provider/chat/message/room_message_service.dart`

**职责描述**: 聊天消息存储器，维护所有房间的消息列表（按 roomId 分组），支持消息同步、加载历史、撤回等操作。

**核心功能**:

| 功能 | 描述 |
|-----|------|
| 消息订阅 | 监听 WebSocket 消息流，自动接收新消息 |
| 消息同步 | 首次进入房间时同步历史消息 |
| 历史加载 | 分页加载更早的历史消息（每页50条） |
| 消息去重 | 通过 clientMsgId 或 messageId 去重 |
| 消息状态 | 跟踪消息投递状态（发送中、已发送、发送失败） |
| 消息撤回 | 调用撤回接口并更新本地列表 |
| 收藏功能 | 收藏指定消息 |

**消息排序规则**:

- 发送中的消息（seq=0）按时间戳升序排在最后
- 其他消息按 seq 升序排列

**Provider 结构**:

```dart
@Riverpod(keepAlive: true)
class ChatMessages extends _$ChatMessages {
  // 消息存储：Map<roomId, List<ChatMessage>>
}

@riverpod
class ChatHasMore extends _$ChatHasMore {
  // 房间是否还有更多历史消息
}
```

---

## 4. 领域模型

### 4.1 ChatMessage

**文件路径**: `lib/framework/domain/ChatMessage.dart`

**职责描述**: 表示聊天会话中的单条消息，包含消息内容、发送者信息、附件和元数据。

**属性说明**:

| 属性名 | 类型 | 默认值 | 描述 |
|-------|------|-------|------|
| `messageId` | `String?` | - | 服务器分配的消息唯一标识 |
| `clientMsgId` | `String?` | - | 客户端生成的消息ID（用于去重） |
| `roomId` | `String?` | - | 所属聊天室ID |
| `senderId` | `int?` | - | 发送者用户ID |
| `senderName` | `String?` | - | 发送者昵称 |
| `senderAvatar` | `String?` | - | 发送者头像 URL |
| `messageType` | `MessageType?` | - | 消息类型 |
| `content` | `String` | `''` | 消息文本内容 |
| `payload` | `MessagePayload?` | - | 消息负载（富文本等） |
| `attachments` | `List<Attachment>` | `[]` | 文件附件列表 |
| `extra` | `Map<String, dynamic>` | `{}` | 扩展字段 |
| `messageStatus` | `MessageState?` | - | 消息状态（已读/未读） |
| `deliveryStatus` | `DeliveryStatus` | `sent` | 消息投递状态 |
| `timestamp` | `int?` | - | 消息时间戳（毫秒） |
| `seq` | `int?` | - | 消息序号（用于排序） |

### 4.2 ChatRoomVO

**文件路径**: `lib/framework/domain/ChatRoomVO.dart`

**职责描述**: 表示单个聊天会话/房间的完整信息。

**属性说明**:

| 属性名 | 类型 | 描述 |
|-------|------|------|
| `roomId` | `String?` | 聊天室唯一标识 |
| `roomName` | `String?` | 聊天室名称 |
| `roomAvatar` | `String?` | 聊天室头像 URL |
| `roomDescription` | `String?` | 聊天室描述/公告 |
| `roomStatus` | `int?` | 聊天室状态：0=正常，1=全员禁言，2=封禁，3=已删除 |
| `roomType` | `int?` | 聊天室类型：0=单聊，1=群聊，2=AI对话 |
| `createdAt` | `DateTime?` | 创建时间 |
| `lastReadSeq` | `int?` | 已读水印（用于未读数计算） |
| `peerId` | `int?` | 对方用户ID（仅单聊时有值） |
| `unreadCount` | `int?` | 未读消息数 |
| `lastMessage` | `ChatMessage?` | 最后一条消息 |

### 4.3 UserInfo

**文件路径**: `lib/framework/domain/UserInfo.dart`

**职责描述**: 表示当前登录用户或指定用户的完整个人资料。

**属性说明**:

| 属性名 | 类型 | 描述 |
|-------|------|------|
| `userId` | `int` | 用户ID |
| `userName` | `String` | 用户账号（登录名称） |
| `nickName` | `String` | 用户昵称 |
| `email` | `String` | 用户邮箱 |
| `phoneNumber` | `String` | 手机号码 |
| `sex` | `String` | 用户性别：0=男，1=女，2=未知 |
| `avatar` | `String` | 用户头像 URL |

---

## 5. Provider 体系

### 5.1 Provider 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        Provider 体系                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │    Auth      │    │     WS       │    │   Router     │       │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤       │
│  │ AuthController│    │  WsController │    │   Router     │       │
│  │ TokenProvider │    │ WsState       │    │ RouterRefresh│       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐       │
│  │                     Chat 模块                         │       │
│  ├──────────────────────────────────────────────────────┤       │
│  │  Message:          │  Room:           │  Call:         │       │
│  │  - ChatMessages    │  - RoomListSvc   │  - CallStatus  │       │
│  │  - RoomMsgService  │  - RoomMemberSvc │  - RoomCtrl    │       │
│  │  - HighMsgService  │  - PinnedRooms   │  - HistoryPanel│       │
│  │  - SystemEventSvc  │  - CreateGroup   │                │       │
│  │  - SearchMsgSvc    │                  │                │       │
│  ├──────────────────────────────────────────────────────┤       │
│  │  Input:            │  Favorite:       │                │       │
│  │  - ChatInputCtrl   │  - ChatFavSvc    │                │       │
│  │  - DeltaProcessor  │                  │                │       │
│  │  - UploadValidator │                  │                │       │
│  │  - FileUploadCtrl  │                  │                │       │
│  │  - ImageUploadCtrl │                  │                │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Contact    │    │    Theme     │    │   Setting    │       │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤       │
│  │ContactListSvc│    │ThemeController│   │SettingsProv  │       │
│  │ContactDetail │    │AppTheme       │    │UpdateCheck   │       │
│  │ContactReqs   │    │               │    │              │       │
│  │UserSearchSvc │    │               │    │              │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 核心 Provider 列表

| Provider 名称 | 类型 | 生命周期 | 描述 |
|---------------|------|---------|------|
| `authControllerProvider` | `AsyncNotifier` | 普通 | 认证状态管理 |
| `tokenCacheProvider` | `Notifier` | 普通 | Token 内存缓存 |
| `wsControllerProvider` | `Notifier` | keepAlive | WebSocket 连接控制 |
| `wsMessageStreamProvider` | `StreamProvider` | 普通 | WebSocket 消息流 |
| `routerProvider` | `Provider` | 普通 | 路由配置 |
| `appInitializerProvider` | `FutureProvider` | 普通 | 应用初始化 |
| `chatMessagesProvider` | `Notifier` | keepAlive | 消息存储 |
| `roomListServiceProvider` | `AsyncNotifier` | keepAlive | 房间列表服务 |
| `appThemeProvider` | `Notifier` | keepAlive | 主题状态 |

---

## 6. 路由与导航

### 6.1 路由配置

**文件路径**: `lib/framework/provider/router/router.dart`

**路由列表**:

| 路由名称 | 路径 | 组件 | 描述 |
|---------|-----|------|------|
| `SplashRoute` | `/splash` | `SplashPage` | 启动页 |
| `HomeRoute` | `/` | `MainLayoutPage` | 首页/主布局 |
| `InitLoginRoute` | `/login` | `LoginPage` | 登录页 |
| `ErrorRoute` | `/error` | `ErrorPage` | 错误页 |
| `ImageMessageDetailRoute` | `/imageView` | `ImageViewer` | 图片预览 |
| `AddFriendRoute` | `/add-friend` | `AddFriendPage` | 添加好友 |

### 6.2 路由守卫机制

**认证状态驱动的重定向**:

```
路由变化时
  │
  ▼
检查 AppInitializer 状态
  │
  ├─ 有错误 ──────────────────────► 跳转 /error
  │
  └─ 无错误
       │
       ▼
    检查 AuthController 状态
       │
       ├─ 未登录 (value=null) ────► 跳转 /login
       │
       ├─ 已登录 (value=UserInfo) ► 跳转 /
       │
       └─ 加载中 ─────────────────► 保持当前页
```

---

## 7. 主题系统

### 7.1 AppTheme

**文件路径**: `lib/framework/theme/AppTheme.dart`

**职责描述**: 应用主题配置，支持 19 种预设主题。

**主题列表**:

| 主题名称 | 亮度 | 主色调 |
|---------|------|-------|
| app_light_themes1 ~ 7 | 亮色 | Indigo, Emerald, Pink, Teal, Gray, Amber, Violet |
| app_dark_themes8 ~ 19 | 暗色 | Blue, Purple, Emerald, Amber, Red, Sky, Amber, Purple, Green, Orange, Cyan, Gray |

### 7.2 ThemeController

**文件路径**: `lib/framework/provider/theme/theme_controller.dart`

**职责描述**: 主题状态控制器，管理主题切换和持久化。

**核心功能**:

- 主题切换
- 主题偏好持久化到 SharedPreferences
- 提供 `appThemeProvider` 获取当前主题

---

## 8. 依赖关系

### 8.1 外部依赖

| 依赖包 | 版本 | 用途 |
|-------|------|------|
| `flutter` | SDK | UI 框架 |
| `flutter_riverpod` | ^3.0.3 | 状态管理 |
| `riverpod_annotation` | ^3.0.3 | Riverpod 代码生成注解 |
| `dio` | ^5.9.0 | HTTP 客户端 |
| `go_router` | ^17.0.0 | 声明式路由 |
| `talker_flutter` | ^5.1.5 | 日志库 |
| `shared_preferences` | ^2.5.3 | 本地存储 |
| `flutter_secure_storage` | ^9.0.0 | 密钥存储 |
| `livekit_client` | ^2.6.2 | 音视频通话 |
| `flutter_webrtc` | ^1.3.0 | WebRTC 支持 |
| `web_socket_channel` | ^3.0.3 | WebSocket |
| `flutter_quill` | ^11.5.0 | 富文本编辑器 |
| `easy_localization` | ^3.0.8 | 国际化 |
| `window_manager` | git | 窗口管理 |
| `desktop_multi_window` | ^0.3.0 | 多窗口支持 |
| `file_picker` | ^11.0.2 | 文件选择 |
| `cached_network_image` | ^3.4.1 | 图片缓存 |

### 8.2 开发依赖

| 依赖包 | 版本 | 用途 |
|-------|------|------|
| `riverpod_generator` | ^3.0.3 | Riverpod 代码生成器 |
| `build_runner` | ^2.10.3 | 代码生成运行器 |
| `go_router_builder` | ^4.1.3 | 路由代码生成器 |
| `flutter_gen_runner` | ^5.12.0 | 资源代码生成器 |

---

## 9. 项目运行方式

### 9.1 环境要求

- Flutter SDK: ^3.10.1
- Dart SDK: ^3.10.1
- 支持的操作系统: Windows, macOS, Linux, Android, iOS, Web

### 9.2 开发环境配置

#### 9.2.1 安装依赖

```bash
# 克隆项目
git clone https://github.com/your-account/Anoxia-IM.git
cd Anoxia-IM/NotePadClient

# 安装依赖
flutter pub get
```

#### 9.2.2 生成代码

```bash
# 生成 Riverpod、GoRouter 等代码
dart run build_runner build --delete-conflicting-outputs

# 生成开源许可证数据（可选）
dart run flutter_oss_licenses:generate
```

#### 9.2.3 启动开发服务器

```bash
# 启动所有平台的开发版本
flutter run

# 指定平台启动
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d android    # Android
flutter run -d ios         # iOS
flutter run -d chrome      # Web
```

### 9.3 常用开发命令

| 命令 | 描述 |
|-----|------|
| `flutter analyze` | 代码静态分析 |
| `flutter test` | 运行测试 |
| `dart run build_runner watch` | 监听代码变化自动重新生成 |
| `flutter clean` | 清理构建缓存 |
| `flutter pub get` | 重新安装依赖 |

### 9.4 API 配置

**文件路径**: `lib/common/constants/API.dart`

```dart
// 生产环境
static const String httpBaseUrl = 'https://chat.anoxia.cn/api';
static const String wsBaseUrl = 'wss://chat.anoxia.cn/chat?token=';
static const String wsRoomBaseUrl = 'wss://live.anoxia.cn';

// 本地开发（需要取消注释）
// static const String httpBaseUrl = 'http://127.0.0.1:8080';
// static const String wsBaseUrl = 'ws://127.0.0.1:8081?token=';
```

---

## 10. 多语言支持

### 10.1 语言资源

**文件路径**: `assets/i18n/`

| 文件 | 语言 |
|-----|------|
| `zh.json` | 中文（简体） |
| `en.json` | 英语 |
| `ja.json` | 日语 |

### 10.2 使用方式

```dart
// 静态文本
Text('hello').tr()

// 带参数的文本
Text('user_count').tr(args: ['10'])

// 复数形式
Text('item_count').trplural('one', 1)
Text('item_count').trplural('other', 10)
```

### 10.3 语言切换

通过 `EasyLocalization` 的 `context.locale` 切换语言，配置存储在 SharedPreferences 中。

---

## 11. 最佳实践

### 11.1 代码规范

1. **文件命名**: 使用小写加下划线（snake_case）
2. **类命名**: 使用大驼峰（PascalCase）
3. **常量命名**: 使用大写下划线（SCREAMING_SNAKE_CASE）
4. **Provider 命名**: 以 `Provider` 结尾

### 11.2 Riverpod 使用规范

1. **使用 `@Riverpod` 注解**定义 Provider
2. **使用 `@riverpod` 注解**的工厂方法定义派生 Provider
3. **使用 `keepAlive: true`**保持长生命周期 Provider
4. **使用 `AsyncValue`**处理异步状态

### 11.3 WebSocket 消息处理规范

1. 在 `main.dart` 中注册协议解析器
2. 通过 `wsControllerProvider` 的 `messageStream` 监听消息
3. 使用 `PacketRegistry.parse()` 解析消息
4. 遵循 `PacketType` 枚举区分消息类型

### 11.4 状态管理规范

1. **认证状态**: 通过 `AuthController` 统一管理
2. **WebSocket 连接**: 通过 `WsController` 统一管理
3. **消息状态**: 通过 `ChatMessages` Provider 集中存储
4. **UI 状态**: 使用 `ConsumerStatefulWidget` 或 `ref.watch`

---

## 12. 常见问题

### 12.1 如何添加新的 API 接口？

1. 在 `lib/common/constants/API.dart` 中添加接口常量
2. 在对应业务 Provider 中使用 `DioClient()` 调用

### 12.2 如何添加新的消息类型？

1. 在 `lib/framework/protocol/message/MessageEunm.dart` 中添加枚举值
2. 创建对应的消息模型类实现 `IPacket` 接口
3. 在 `main.dart` 的 `_registerPacketParsers()` 中注册解析器

### 12.3 如何添加新的 Provider？

1. 在对应模块目录下创建文件
2. 使用 `@Riverpod` 或 `@riverpod` 注解
3. 运行 `dart run build_runner build` 生成代码

### 12.4 如何自定义主题？

在 `lib/framework/theme/AppTheme.dart` 的 `themes` 列表中添加新的 `ThemeOption`。

---

## 附录 A: API 接口清单

| 接口分类 | 接口路径 | 方法 | 描述 |
|---------|---------|------|------|
| 认证 | `/login` | POST | 用户登录 |
| 认证 | `/logout` | POST | 用户登出 |
| 认证 | `/getInfo` | GET | 获取用户信息 |
| 认证 | `/captchaImage` | GET | 获取验证码 |
| 联系人 | `/contact/list` | GET | 获取联系人列表 |
| 联系人 | `/contact/request` | POST | 发送好友请求 |
| 聊天室 | `/chat/rooms` | GET | 获取聊天室列表 |
| 聊天室 | `/chat/createPrivate` | POST | 创建私聊 |
| 聊天室 | `/chat/createGroup` | POST | 创建群聊 |
| 消息 | `/chat/history` | GET | 获取历史消息 |
| 消息 | `/chat/search` | GET | 搜索消息 |
| 消息 | `/chat/recall` | GET | 撤回消息 |
| 通话 | `/call/token` | GET | 获取通话 Token |
| 更新 | `/app/update/latest` | GET | 检查版本更新 |

---

*最后更新: 2026-05-14*
