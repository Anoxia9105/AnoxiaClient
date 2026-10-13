# 平台行为与开发注意事项

## Android 返回

系统返回优先关闭键盘、弹窗和当前子页面。根路由无法返回时，`MainActivity.popSystemNavigator()` 调用 `moveTaskToBack(true)`，将应用退到后台。强制更新页的退出通过 `app_navigation/exitApp` 显式结束 Activity。

Manifest 开启 `enableOnBackInvokedCallback`；`setFrameworkHandlesBack()` 保持 Flutter 返回回调注册，避免根页面返回绕过后台化处理。后台化不保证进程常驻，仍需处理系统回收、推送与重连。

相关回归：`test/features/app/android_back_navigation_test.dart`、`test/features/update/update_page_test.dart`。预测性返回、手势取消及后台恢复还需真机验证。

## 桌面文件拖放

正常聊天房间支持拖入图片、视频和文件。松手后插入 Quill 草稿并后台上传，由用户确认发送。`DesktopChatDropTarget`、`prepareDesktopDropFiles` 与 `ChatFileUploadController.insertPickedFiles` 复用现有附件链路。

- 跳过文件夹、不可读文件和同批重复路径；限制沿用 `UploadValidator`，包含草稿中已有附件。
- 官方房间、初始化中、禁言、封禁、解散、弹窗覆盖时不接收拖放。
- 准备附件期间切房间或销毁页面，取消尚未插入的批次；已插入附件保留上传与重试生命周期。
- 区分真实本地路径、`local-pending://` 和 `blob:` 占位地址，避免误判可上传资源。
- macOS 沙箱通过 `com.apple.security.files.user-selected.read-only` 读取用户选取或拖入的文件。

相关回归：`desktop_drop_files_test.dart`、`desktop_chat_drop_target_test.dart`、`desktop_drop_upload_test.dart`、`desktop_upload_multipart_test.dart`、`file_embed_retry_test.dart`，均位于 `test/features/chat/`。新增原生插件后需完整重启应用。

## macOS 窗口与通话启动

macOS 主窗口与通话窗口保留左上角原生红黄绿按钮，Logo 移至标题栏最右侧。左侧为原生按钮预留 80 个逻辑像素，返回按钮和连接状态从留白之后显示；不再显示右侧重复的最小化、最大化和关闭控件。Windows 保留左侧 Logo 和右侧自绘窗口控件。标题栏拖动继续由 `DragToMoveArea` 处理；原生关闭按钮沿用主窗口退出/驻留托盘和通话窗口先释放媒体再关闭的既有流程。

通话子窗口拥有独立 Flutter 引擎。`MainFlutterWindow.swift` 必须通过 `FlutterMultiWindowPlugin.setOnWindowCreatedCallback` 给每个新引擎执行 `RegisterGeneratedPlugins`，否则热键、窗口管理、存储和媒体等插件可能抛出 `MissingPluginException`。全局热键清理、自启设置和后台更新检查仅在主窗口初始化，子窗口不能清除主窗口快捷键或重复运行应用级任务。

运行时 `.ico` 窗口图标仅在 Windows 设置；macOS 使用应用包图标，不调用没有原生实现的 `setIcon`。

相关回归：`macos_title_bar_test.dart`、`desktop_window_setup_test.dart`、`desktop_window_close_test.dart`（`test/common/widgets/desktop/`），以及 `window_call_teardown_test.dart`（`test/features/chat/presentation/call/`）。Windows 上可以覆盖 Dart 平台分支和窗口方法调用，不能代替 macOS 原生编译及真实通话验收。Swift 注册回调改动需在 Mac 上重新构建安装，热重载不能使其生效。

## 移动端聊天面板与拍摄

更多面板每页四列两排，提供拍摄、图片、文件、@、收藏、个人名片、语音和视频通话；超过八项时分页。

拍摄支持前后摄、设备允许时的补光、短按拍照、长按录像及预览重拍。后台释放相机，恢复前台后重新初始化；通话期间避免争抢摄像头与麦克风。相机权限、硬件能力与生命周期须在 Android/iOS 真机验证，iOS 最低部署版本为 13.0。

发送收藏保留媒体、富文本和卡片快照，剥离原会话的回复与提及上下文；发送联系人名片仅包含公开资料，不包含本地备注。

## 列表刷新

手机与窄屏 Web 支持下拉刷新，桌面与宽屏 Web 提供标题栏刷新按钮。空态、少量联系人和错误态也应可刷新；多个刷新入口等待同一个进行中的 Future，避免重复请求。

刷新保留既有数据，失败时保留重试入口。首次加载、缓存与错误状态约定见 [聊天与联系人加载状态](./chat_loading_states.md)。

## 错误页面

运行时错误页继承当前应用主题和语言，使用主题卡片、标准圆角按钮与强调色；有重试回调时突出重试，否则突出复制错误信息。技术详情默认折叠，可展开滚动和选择，复制保留完整原始异常；剪贴板返回成功后才提示复制成功，失败反馈同样国际化。

启动失败使用独立 `StartupErrorApp`，不依赖业务 Provider 或 EasyLocalization 初始化成功，读取已保存的语言、亮暗模式、预设/自定义强调色，并使用相同的 `AppTheme`。系统模式继续跟随系统亮暗切换。语言包尚未可用时，`ErrorPageStrings` 提供中英日最小兜底；测试对照正式 JSON，避免文案漂移。启动错误不拼接中文异常前缀，用户提示与原始异常分开显示。

相关回归：`test/features/app/error_page_test.dart`，覆盖无 EasyLocalization 的三语、保存主题、系统模式、小窗口和剪贴板异步成功/失败。
