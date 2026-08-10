# Anoxia IM - Code Wiki 文档

## 1. 项目概述

### 1.1 项目简介

**Anoxia IM** 是一个基于 Flutter 3.x 构建的高性能跨平台即时通讯（IM）客户端应用。项目采用 Dart 作为开发语言，支持 Android、iOS、Windows、macOS、Linux 和 Web 等多个平台。

### 1.2 核心功能特性

| 功能模块 | 功能描述 |
|---------|---------|
| 即时消息 | 支持文本、图片、文件、富文本等多类型消息，支持消息撤回、收藏 |
| 音视频通话 | 基于 LiveKit + WebRTC 实现实时音视频通话能力，支持表情反应特效 |
| 联系人管理 | 好友申请、联系人列表、群组管理 |
| 富文本输入 | 基于 Flutter Quill 实现支持 Mention、文件嵌入的富文本编辑器 |
| 多窗口支持 | 桌面端支持多窗口通话页面 |
| 直播功能 | 支持直播列表、直播间观看、弹幕互动 |
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
│  shared_preferences + flutter_secure_storage + sqlite  │
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
│      │         │    │  ┌─────┬──────┬───────┬──────┬─────┐ │    │
│      │         │    │  │core │domain│network│protocol│theme│ │    │
│      │         │    │  └─────┴──────┴───────┴──────┴─────┘ │    │
│      │         │    │  ┌────────────────────────────────┐  │    │
│      │         │    │  │          provider/              │  │    │
│      │         │    │  │  ┌────┬─────┬──────┬─────┐   │ │  │    │
│      │         │    │  │  │auth│chat │contact│live │... │ │  │    │
│      │         │    │  │  └────┴─────┴──────┴─────┘   │ │  │    │
│      │         │    │  └────────────────────────────────┘  │    │
│      │         │    │  ┌──────────┬───────────────┐       │    │
│      │         │    │  │  codec   │  local_cache  │       │    │
│      │         │    │  └──────────┴───────────────┘       │    │
│      │         │    └──────────────────────────────────────┘    │
│      │         │                                              │
│      │         │    ┌──────────────────────────────────────┐    │
│      │         │    │            features/                 │    │
│      │         │    │  ┌──────┬──────┬────────┬────────┐ │    │
│      │         │    │  │  app │ chat │ contact│  live  │ │    │
│      │         │    │  └──────┴──────┴────────┴────────┘ │    │
│      │         │    │  ┌──────┬──────┬────────┐         │    │
│      │         │    │  │favorite│  me │ settings│        │    │
│      │         │    │  └──────┴──────┴────────┘         │    │
│      │         │    └──────────────────────────────────────┘    │
└──────┴─────────┴─────────────────────────────────────────────────┘
```

### 2.2 目录结构说明

```
lib/
├── main.dart                    # 应用程序入口文件
├── app.dart                     # 应用根组件
├── gen/                         # 资源生成代码
│   ├── assets.gen.dart          # 静态资源引用
│   └── fonts.gen.dart           # 字体资源引用
│
├── common/                      # 通用模块（工具、常量、基础组件）
│   ├── constants/
│   │   ├── api.dart               # API 接口地址常量
│   │   └── storage_keys.dart      # 存储键名常量
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
│       ├── BreathingDot.dart
│       ├── CustomButton.dart
│       ├── FocusOverlayManager.dart
│       ├── NoData.dart
│       ├── SimpleListTile.dart
│       ├── SkeletonBox.dart
│       ├── Toast.dart
│       ├── VibratingBadge.dart
│       ├── Welcome.dart
│       ├── ws_connection_banner.dart
│       ├── app/                  # 应用级组件
│       │   ├── MobileBottomBar.dart
│       │   └── app_scaffold.dart
│       └── desktop/             # 桌面端组件
│           ├── ConnectionStatusTag.dart
│           ├── DesktopAppBar.dart
│           ├── DesktopSidebar.dart
│           ├── GlobalSearchDialog.dart
│           └── HeaderSearchEntry.dart
│
├── framework/                   # 核心框架层
│   ├── codec/                   # 协议编解码层
│   │   ├── FrameCodec.dart
│   │   ├── ProtoReader.dart
│   │   ├── ProtoWriter.dart
│   │   └── v5/
│   │       └── ImPacketV5.dart
│   ├── core/                    # 核心基础设施
│   │   ├── app_globals.dart     # 全局变量
│   │   └── push_manager.dart    # 推送管理器
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
│   │   ├── RoomState.dart        # 通话房间状态
│   │   ├── upload_entry.dart
│   │   ├── UserInfo.dart         # 用户信息模型
│   │   ├── UserSearchResponse.dart
│   │   └── UserVO.dart
│   ├── extensions/               # 扩展方法
│   │   ├── QuillCursorX.dart
│   │   └── window_controller.dart
│   ├── local_cache/              # 本地缓存层
│   │   ├── cache_providers.dart
│   │   ├── database.dart         # SQLite 数据库
│   │   ├── database.g.dart       # 数据库生成代码
│   │   ├── local_data_source.dart
│   │   ├── remote_data_source.dart
│   │   ├── sync_repository.dart
│   │   └── tables.dart           # 数据库表定义
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
│   │   ├── ai/                   # AI 对话
│   │   │   ├── ai_chat_controller.dart
│   │   ├── auth/                 # 认证
│   │   │   ├── auth_controller.dart
│   │   │   └── token_provider.dart
│   │   ├── chat/                 # 聊天模块
│   │   │   ├── call/             # 音视频通话
│   │   │   │   ├── channel.dart
│   │   │   │   ├── layout_mode.dart
│   │   │   │   ├── call_status_provider.dart
│   │   │   │   ├── call_window_controller.dart
│   │   │   │   ├── mobile_call_session_provider.dart
│   │   │   │   └── room_controller.dart
│   │   │   ├── favorite/         # 消息收藏
│   │   │   │   └── chat_favorite_service.dart
│   │   │   ├── input/            # 输入控制
│   │   │   │   ├── files/        # 文件上传
│   │   │   │   │   └── chat_file_upload_controller.dart
│   │   │   │   ├── images/       # 图片上传
│   │   │   │   │   └── chat_image_upload_controller.dart
│   │   │   │   ├── DeltaProcessor.dart
│   │   │   │   ├── UploadValidator.dart
│   │   │   │   ├── chat_audio_player_manager.dart
│   │   │   │   ├── chat_input_controller.dart
│   │   │   │   ├── mobile_text_input_controller.dart
│   │   │   │   ├── reply_target_provider.dart
│   │   │   │   └── voice_record_controller.dart
│   │   │   ├── message/          # 消息服务
│   │   │   │   ├── high_message_service.dart
│   │   │   │   ├── reply_jump_provider.dart
│   │   │   │   ├── room_message_service.dart
│   │   │   │   ├── room_message_ui_item_service.dart
│   │   │   │   ├── search_message_service.dart
│   │   │   │   ├── system_event_service.dart
│   │   │   │   └── system_message_service.dart
│   │   │   └── room/             # 房间管理
│   │   │       ├── chat_split_view_provider.dart
│   │   │       ├── create_new_gropu_controller.dart
│   │   │       ├── pinned_rooms_provider.dart
│   │   │       ├── room_list_service.dart
│   │   │       ├── room_lookup_helper.dart
│   │   │       └── room_member_service.dart
│   │   ├── contact/              # 联系人
│   │   │   ├── contact_detail_controller.dart
│   │   │   ├── contact_list_controller.dart
│   │   │   ├── contact_requests_controller.dart
│   │   │   ├── contact_selection_controller.dart
│   │   │   └── user_search_service.dart
│   │   ├── core/                 # 核心服务
│   │   │   ├── AppUpdateInfo.dart
│   │   │   ├── app_initializer.dart
│   │   │   ├── login_bootstrap_orchestrator.dart
│   │   │   ├── network_provider.dart
│   │   │   └── session_reset_service.dart
│   │   ├── desktop/              # 桌面端
│   │   │   └── desktop_search_controller.dart
│   │   ├── layout/               # 布局管理
│   │   │   └── layout_controller.dart
│   │   ├── live/                 # 直播
│   │   │   └── live_room_controller.dart
│   │   ├── router/               # 路由
│   │   │   └── router.dart
│   │   ├── setting/              # 设置
│   │   │   ├── settings_provider.dart
│   │   │   └── update_check_provider.dart
│   │   ├── theme/                # 主题
│   │   │   └── theme_controller.dart
│   │   └── ws/                   # WebSocket
│   │       ├── ws_controller.dart
│   │       └── ws_state.dart
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
    │           ├── forgot_password_page.dart
    │           ├── login_page.dart
    │           ├── main_layout_page.dart
    │           └── splash_page.dart
    ├── chat/                      # 聊天模块
    │   ├── models/
    │   │   ├── chatInput_state.dart
    │   │   ├── chat_message_extensions.dart
    │   │   └── message_item.dart
    │   └── presentation/
    │       ├── call/              # 通话功能
    │       │   ├── component/
    │       │   │   ├── deesktop/
    │       │   │   │   └── call_desktop_app_bar.dart
    │       │   │   ├── command_bar.dart
    │       │   │   ├── participant_tile.dart
    │       │   │   ├── reaction_overlay.dart   # 表情反应特效
    │       │   │   ├── volume_indicator.dart
    │       │   │   └── window_screen_select_dialog.dart
    │       │   ├── desktop/
    │       │   │   ├── room_layout/
    │       │   │   │   ├── layout_room_carousel_widget.dart
    │       │   │   │   ├── layout_room_screen_widget.dart
    │       │   │   │   └── layout_room_widget.dart
    │       │   │   └── call_window_room_body.dart
    │       │   ├── mobile/
    │       │   │   └── call_mobile_room_body.dart
    │       │   ├── call_room_page.dart
    │       │   ├── global_call_overlay.dart
    │       │   ├── mobile_call_page.dart
    │       │   └── window_call_page.dart
    │       ├── pages/
    │       │   ├── add_member_page.dart
    │       │   ├── banned_content_page.dart
    │       │   ├── chat_page.dart
    │       │   ├── chat_room_detail_page.dart
    │       │   ├── chat_room_detail_settings_page.dart
    │       │   ├── chat_room_list_page.dart
    │       │   ├── empty_messages_page.dart
    │       │   ├── group_edit_announcement_page.dart
    │       │   ├── group_edit_name_page.dart
    │       │   ├── group_member_list_page.dart
    │       │   ├── no_conversation_page.dart
    │       │   └── scan_qr_page.dart
    │       └── widgets/
    │           ├── appbar/
    │           │   ├── chat_app_bar.dart
    │           │   ├── chat_bar_handlers.dart
    │           │   ├── chat_call_button_widget.dart
    │           │   └── chat_group_action_buttons_widget.dart
    │           ├── chatinput/
    │           │   ├── desktop/
    │           │   │   ├── quill/
    │           │   │   │   ├── embedBuilder/
    │           │   │   │   │   ├── quill_file_build.dart
    │           │   │   │   │   ├── quill_image_build.dart
    │           │   │   │   │   └── quill_mention_build.dart
    │           │   │   │   ├── card_box.dart
    │           │   │   │   ├── chat_quill_toolbar.dart
    │           │   │   │   ├── colors_box.dart
    │           │   │   │   ├── location_box.dart
    │           │   │   │   └── quill_style_config.dart
    │           │   │   └── desktop_chat_input.dart
    │           │   ├── mobile/
    │           │   │   ├── chat_action_item.dart
    │           │   │   ├── chat_more_panel.dart
    │           │   │   ├── chat_voice_overlay.dart
    │           │   │   └── mobile_chat_input.dart
    │           │   ├── chat_emoji_widget.dart
    │           │   ├── chat_input_field.dart
    │           │   ├── chat_room_detail_bottom_bar.dart
    │           │   ├── chat_room_detail_scroll_down_button.dart
    │           │   ├── chat_room_detail_status_tag.dart
    │           │   ├── reply_preview_bar.dart
    │           │   └── skeleton/
    │           │       └── chat_input_skeleton.dart
    │           ├── message_bubble/
    │           │   ├── bubble_shell.dart
    │           │   ├── chat_message_bubble.dart
    │           │   ├── message_bubble_view_data.dart
    │           │   ├── message_resender.dart
    │           │   ├── message_status_indicators.dart
    │           │   ├── system_message_bubble.dart
    │           │   └── user_message_bubble.dart
    │           ├── message_menu/
    │           │   └── chat_message_context_menu.dart
    │           ├── message_render/
    │           │   ├── base/
    │           │   │   ├── message_render_factory.dart
    │           │   │   └── message_render_strategy.dart
    │           │   ├── detail/
    │           │   │   └── image_viewer.dart
    │           │   ├── audio_message_strategy.dart
    │           │   ├── card_message_strategy.dart
    │           │   ├── file_message_strategy.dart
    │           │   ├── image_message_strategy.dart
    │           │   ├── link_preview_card.dart
    │           │   ├── location_message_strategy.dart
    │           │   ├── quill_message_strategy.dart
    │           │   ├── system_message_strategy.dart
    │           │   └── text_message_strategy.dart
    │           ├── room_detail_settings/
    │           │   ├── member_grid_section.dart
    │           │   └── room_card.dart
    │           ├── skeleton/
    │           │   ├── chat_room_detail_skeleton.dart
    │           │   ├── chat_room_list_item_skeleton.dart
    │           │   └── chat_room_list_skeleton.dart
    │           ├── add_member_dialog_widget.dart
    │           ├── create_chat_dialog_widget.dart
    │           ├── mention_list_widget.dart
    │           ├── room_list_dialog_menus.dart
    │           ├── room_list_item.dart
    │           └── search_context_page.dart
    ├── contact/                   # 联系人模块
    │   └── presentation/
    │       ├── pages/
    │       │   ├── add_friend_page.dart
    │       │   ├── contact_detail_page.dart
    │       │   ├── contact_page.dart
    │       │   ├── group_room_list_page.dart
    │       │   └── new_friends_page.dart
    │       └── widgets/
    │           ├── add_friend_widgets.dart
    │           ├── contact_detail_widgets.dart
    │           ├── contact_list.dart
    │           ├── group_room_widgets.dart
    │           ├── new_friends_widgets.dart
    │           └── sorted_contact_groups_widget.dart
    ├── favorite/                  # 收藏模块
    │   └── presentation/
    │       └── pages/
    │           └── favorites_page.dart
    ├── live/                      # 直播模块
    │   └── presentation/
    │       └── pages/
    │           ├── live_list_page.dart
    │           ├── live_preview_page.dart
    │           ├── live_room_page.dart
    │           ├── window_live_danmaku_page.dart
    │           ├── window_live_page.dart
    │           └── window_live_preview_page.dart
    ├── me/                        # 个人中心模块
    │   └── presentation/
    │       ├── pages/
    │       │   ├── change_password_page.dart
    │       │   ├── me_page.dart
    │       │   ├── me_profile_item_edit_page.dart
    │       │   ├── menu_page.dart
    │       │   └── personal_qr_page.dart
    │       └── widgets/
    │           └── me_header_widgets.dart
    ├── settings/                  # 设置模块
    │   ├── application/
    │   │   └── settings_page_controller.dart
    │   └── presentation/
    │       ├── pages/
    │       │   ├── developer_tribute_page.dart
    │       │   ├── open_source_licenses_page.dart
    │       │   └── settings_page.dart
    │       └── widgets/
    │           ├── settings_about_support_section.dart
    │           ├── settings_feedback_section.dart
    │           ├── settings_font_section.dart
    │           ├── settings_item_card.dart
    │           ├── settings_language_section.dart
    │           └── settings_theme_section.dart
    └── update/                    # 更新模块
        └── presentation/
            ├── pages/
            │   └── update_page.dart
            └── widgets/
                └── update_sections.dart
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
| `runSubApp()` | `Future<void>` | 启动子窗口（通话/直播窗口），使用隔离 Provider 容器 |
| `runUpdateApp()` | `Future<void>` | 启动更新窗口，显示版本更新信息 |
| `setupDesktopWindow()` | `Future<void>` | 配置桌面窗口尺寸和样式 |
| `_createIsolatedWindowContainer()` | `Future<ProviderContainer>` | 为桌面子窗口创建局部容器，仅同步认证 token |
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

**桌面多窗口容器策略**:

```dart
final ProviderContainer globalContainer = ProviderContainer();
```

主窗口和更新窗口使用 `globalContainer` 持有应用级状态。桌面子窗口必须通过 `_createIsolatedWindowContainer()` 创建独立 `ProviderContainer`，只从 `TokenManager` 恢复并写入 `tokenCacheProvider`，不能复用主窗口容器。

这样可以避免 `RoomController`、`ChatMessages`、`WsController` 等 keepAlive Provider 在多窗口之间共享单例状态，导致通话窗口污染主窗口当前聊天室、消息列表或媒体状态。子窗口需要的聊天室、通话、直播和 WebSocket 状态应在自己的组件树内按需构建。

#### 3.1.2 app.dart

**文件路径**: `lib/app.dart`

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
| `deliveryStatus` | `DeliveryStatus` | 前端本地投递状态（不属于 RoomMessage 协议） |
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
| 自动重连 | 指数退避 + Full Jitter，最大 30s，避免客户端同一时间批量重连 |
| 消息分发 | 将接收到的消息通过 Stream 分发给各 Consumer |
| 错误处理 | 解析 ACK 错误码，显示 Toast 提示（2秒内重复错误不重复提示） |

**重连策略**:

```dart
// 重连间隔计算
final baseDelay = (1 << _reconnectAttempts).clamp(2, 30);
final jitterMs = math.Random().nextInt(baseDelay * 1000);
final delaySeconds = math.max(1, (jitterMs / 1000).round());
```

固定的 2s/4s/8s 重连会在后端重启时形成惊群效应。`WsController` 使用 Full Jitter 后，同一批客户端会被随机分散到 `[1, baseDelay]` 秒区间内重连，降低 Redis、MySQL 和鉴权接口的瞬时压力。

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
| `loginByScanToken()` | `Future<void>` | 扫码登录（手机确认后签发 token 完成登录） |
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
| 消息同步 | 首次进入房间时按本地最大连续 seq 水印同步增量消息 |
| 历史加载 | 基于 `before_seq` 加载更早历史消息（每页50条） |
| 消息去重 | 通过 clientMsgId 或 messageId 去重 |
| 消息状态 | 跟踪消息投递状态（发送中、已发送、发送失败） |
| 消息撤回 | 调用撤回接口并更新本地列表 |
| 收藏功能 | 收藏指定消息 |

**消息排序规则**:

- 发送中的消息（seq=0）按时间戳升序排在最后
- 其他消息按 seq 升序排列

**同步与分页规则**:

- 增量同步不能使用本地最大 seq，必须使用本地最大连续 seq 作为已读/已收水印，避免本地 SQLite 存在空洞时跳过缺失消息。
- 重复进入同一房间时，`RoomMessageService.syncRoomMessages()` 必须先检查内存消息与最新本地页；当本地最新 seq 已覆盖到服务端 `lastMessage.seq` 时，直接返回，不能请求历史接口。
- 本地加载更多历史时使用 `beforeSeq` 查询 `seq < oldestSeq` 的消息，不使用列表长度 offset。
- 远端历史接口使用 `before_seq` 定向分页，并保留 `lastSeq + direction` 作为当前后端兼容参数。
- `SyncRepository.syncMessages()` 会读取 `LocalDataSource.maxContinuousMessageSeq()`，再向 `/chat/history` 上报该水印做断点续传。
- 进入房间后的已读同步只在存在未读数或待上报 seq 时触发；对已经为 0 未读的房间重复点击，不应再次调用本地/远端 `markAsRead`。
- 离线待发送消息以 SQLite 中的 `SENDING` / `FAILED` 状态为唯一队列来源，由 `SyncRepository.retryPendingOutgoing()` 在网络恢复时重试；`WsController` 不再维护 SharedPreferences 离线二进制帧队列。

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

#### 3.4.4 RoomController (通话控制器)

**文件路径**: `lib/framework/provider/chat/call/room_controller.dart`

**职责描述**: 音视频通话控制器，基于 LiveKit 实现房间管理、参与者状态、通话控制和表情反应功能。

**核心功能**:

| 功能 | 描述 |
|-----|------|
| 房间管理 | 加入/离开通话房间 |
| 媒体控制 | 麦克风开关、摄像头开关、屏幕共享 |
| 参与者管理 | 参与者列表、角色权限、举手状态 |
| 表情反应 | 发送/接收表情反应，3秒自动消失 |
| 数据通道 | 发送/接收自定义数据事件 |

**表情反应流程**:

```
sendReaction(emoji)
  ├── 创建 ReactionItem（包含唯一 id）
  ├── 添加到 RoomState.reactions 列表
  ├── 启动 3 秒 Timer，到期后按 id 删除
  └── 通过 publishData 广播给房间内其他用户
```

#### 3.4.5 扫码登录 (ScanLoginController)

**文件路径**: `lib/framework/provider/auth/scan_login_controller.dart`（展示端轮询）、`lib/features/app/presentation/pages/scan_login_confirm_page.dart`（手机确认端）、`lib/framework/domain/scan_login_model.dart`（模型）

**职责描述**: 桌面/Web 端展示二维码、手机 App 扫码确认，为当前账号签发新设备登录令牌。

**完整流程**:

```
桌面/Web 登录页（密码登录/扫码登录切换）
  │  POST /login/scan/create ──→ ticket + qrContent + expiresIn(120s)
  ▼
QrImageView 渲染二维码（https://<host>/qrlogin?ticket=xxx）
  │  每 2s 轮询 GET /login/scan/status?ticket=xxx
  ▼
手机扫描二维码 → 解析 /qrlogin?ticket= → ScanLoginConfirmPage
  │  点击确认 → POST /login/scan/confirm（deviceId + ticket，限频）
  ▼
服务端确认 → 桌面端轮询到 confirmed + token → loginByScanToken() 完成登录
```

**关键规则**:

- 二维码过期（expired）时轮询自动重新创建会话，无需用户干预；页面销毁时自动取消轮询（`ref.onDispose`）。
- 会话 Redis TTL 120s，一次性防重放；确认成功后签发新设备 token。
- `loginByScanToken` 失败时转为 ASyncError 态展示重试，避免轮询 catch 静默吞错。
- 手机端通过 `DeviceIdentity.getPlatformQualifiedId()` 上报设备标识，与登录/登出链路一致的设备维度清理。

---

### 3.5 媒体处理模块

#### 3.5.1 表情反应特效

**文件路径**: `lib/features/chat/presentation/call/component/reaction_overlay.dart`

**职责描述**: 通话界面的表情反应全屏特效组件，监听 `RoomState.reactions` 列表，展示缩放+淡出动画。

**动画流程**:

| 阶段 | 时间 | 效果 |
|-----|------|------|
| 入场 | 0-400ms | 从 0.3 弹性缩放到 1.2 |
| 保持 | 400-2200ms | 保持显示 |
| 退场 | 2200-3000ms | 淡出消失 |

**组件结构**:

- `ReactionOverlay`: 管理所有活动的表情气泡
- `_ReactionBubble`: 单个表情气泡，包含动画控制器

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
| `deliveryStatus` | `DeliveryStatus` | `sent` | 前端本地投递状态（不属于 RoomMessage 协议） |
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

### 4.3 RoomState

**文件路径**: `lib/framework/domain/RoomState.dart`

**职责描述**: 通话房间状态，包含参与者、通话状态、表情反应等信息。

**属性说明**:

| 属性名 | 类型 | 描述 |
|-------|------|------|
| `room` | `Room?` | LiveKit Room 实例 |
| `participants` | `List<Participant>` | 参与者列表 |
| `localParticipant` | `LocalParticipant?` | 本地参与者 |
| `callStatus` | `CallStatus` | 通话状态 |
| `handRaiseMap` | `Map<String, bool>` | 举手状态映射 |
| `reactions` | `List<ReactionItem>` | 表情反应列表 |
| `layoutMode` | `LayoutMode` | 视频布局模式 |

### 4.4 UserInfo

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
│  │  - HighMsgService  │  - PinnedRooms   │  - CallWindow  │       │
│  │  - SystemEventSvc  │  - CreateGroup   │  - MobileSession│      │
│  │  - SearchMsgSvc    │  - SplitView     │                │       │
│  ├──────────────────────────────────────────────────────┤       │
│  │  Input:            │  Favorite:       │                │       │
│  │  - ChatInputCtrl   │  - ChatFavSvc    │                │       │
│  │  - DeltaProcessor  │                  │                │       │
│  │  - UploadValidator │                  │                │       │
│  │  - FileUploadCtrl  │                  │                │       │
│  │  - ImageUploadCtrl │                  │                │       │
│  │  - VoiceRecordCtrl │                  │                │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Contact    │    │    Live       │    │   Setting    │       │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤       │
│  │ContactListSvc│    │LiveRoomCtrl   │   │SettingsProv  │       │
│  │ContactDetail │    │               │    │UpdateCheck   │       │
│  │ContactReqs   │    │               │    │              │       │
│  │UserSearchSvc │    │               │    │              │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Desktop    │    │    Theme     │    │    Core      │       │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤       │
│  │DesktopSearch │    │ThemeController│   │AppInitializer│       │
│  │               │    │AppTheme       │    │NetworkProv   │       │
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
| `roomControllerProvider` | `Notifier` | keepAlive | 通话房间控制器 |
| `liveRoomControllerProvider` | `Notifier` | keepAlive | 直播房间控制器 |
| `contactListServiceProvider` | `AsyncNotifier` | keepAlive | 联系人列表服务 |
| `appThemeProvider` | `Notifier` | keepAlive | 主题状态 |
| `settingsProvider` | `Notifier` | keepAlive | 设置状态 |

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
| `cross_cache` | ^1.1.0 | 跨平台图片/二进制缓存，Web 使用 IndexedDB，IO 使用本地缓存目录 |
| `drift` | ^2.19.0 | SQLite ORM |

### 8.2 开发依赖

| 依赖包 | 版本 | 用途 |
|-------|------|------|
| `riverpod_generator` | ^3.0.3 | Riverpod 代码生成器 |
| `build_runner` | ^2.10.3 | 代码生成运行器 |
| `go_router_builder` | ^4.1.3 | 路由代码生成器 |
| `flutter_gen_runner` | ^5.12.0 | 资源代码生成器 |
| `drift_dev` | ^2.19.0 | Drift 数据库代码生成器 |

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
cd Anoxia-IM/AnoxiaClient

# 安装依赖
flutter pub get
```

#### 9.2.2 生成代码

```bash
# 生成 Riverpod、GoRouter、Drift 等代码
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

**文件路径**: `lib/common/constants/api.dart`

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
4. **通话状态**: 通过 `RoomController` 统一管理
5. **UI 状态**: 使用 `ConsumerStatefulWidget` 或 `ref.watch`
6. **桌面多窗口**: 子窗口必须使用独立 `ProviderContainer`，只同步 token，不共享主窗口聊天室、通话、消息和 WebSocket Provider 状态

### 11.5 媒体资源规范

1. 使用 `flutter_gen` 生成资源引用代码
2. 通过 `Assets` 类访问资源
3. 图片资源放在 `assets/images/`
4. 音频资源放在 `assets/audio/`

---

## 12. 常见问题

### 12.1 如何添加新的 API 接口？

1. 在 `lib/common/constants/api.dart` 中添加接口常量
2. 在对应业务 Provider 中使用 `DioClient()` 调用

### 12.2 如何添加新的消息类型？

1. 在 `lib/framework/protocol/message/MessageEunm.dart` 中添加枚举值
2. 创建对应的消息模型类实现 `IPacket` 接口
3. 在 `main.dart` 的 `_registerPacketParsers()` 中注册解析器
4. 在 `lib/features/chat/presentation/widgets/message_render/` 中添加渲染策略

### 12.3 如何添加新的 Provider？

1. 在对应模块目录下创建文件
2. 使用 `@Riverpod` 或 `@riverpod` 注解
3. 运行 `dart run build_runner build` 生成代码

### 12.4 如何自定义主题？

在 `lib/framework/theme/AppTheme.dart` 的 `themes` 列表中添加新的 `ThemeOption`。

### 12.5 如何添加表情反应？

在通话界面中，通过 `CommandBar` 组件的 `_showReactionPicker()` 方法选择表情，发送后会在屏幕中央展示 3 秒的全屏特效动画。

---

## 附录 A: API 接口清单

| 接口分类 | 接口路径 | 方法 | 描述 |
|---------|---------|------|------|
| 认证 | `/login` | POST | 用户登录 |
| 认证 | `/logout` | POST | 用户登出 |
| 认证 | `/getInfo` | GET | 获取用户信息 |
| 认证 | `/captchaImage` | GET | 获取验证码 |
| 认证 | `/login/scan/create` | POST | 创建扫码登录会话 |
| 认证 | `/login/scan/status` | GET | 查询扫码登录状态 |
| 认证 | `/login/scan/confirm` | POST | 手机确认扫码登录 |
| 联系人 | `/contact/list` | GET | 获取联系人列表 |
| 联系人 | `/contact/request` | POST | 发送好友请求 |
| 聊天室 | `/chat/rooms` | GET | 获取聊天室列表 |
| 聊天室 | `/chat/createPrivate` | POST | 创建私聊 |
| 聊天室 | `/chat/createGroup` | POST | 创建群聊 |
| 消息 | `/chat/history` | GET | 获取历史消息 |
| 消息 | `/chat/search` | GET | 搜索消息 |
| 消息 | `/chat/recall` | GET | 撤回消息 |
| 通话 | `/call/token` | GET | 获取通话 Token |
| 直播 | `/live/list` | GET | 获取直播列表 |
| 直播 | `/live/enter` | POST | 进入直播间 |
| 更新 | `/app/update/latest` | GET | 检查版本更新 |

---

*最后更新: 2026-08-10*
