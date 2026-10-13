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

## 移动端聊天面板与拍摄

更多面板每页四列两排，提供拍摄、图片、文件、@、收藏、个人名片、语音和视频通话；超过八项时分页。

拍摄支持前后摄、设备允许时的补光、短按拍照、长按录像及预览重拍。后台释放相机，恢复前台后重新初始化；通话期间避免争抢摄像头与麦克风。相机权限、硬件能力与生命周期须在 Android/iOS 真机验证，iOS 最低部署版本为 13.0。

发送收藏保留媒体、富文本和卡片快照，剥离原会话的回复与提及上下文；发送联系人名片仅包含公开资料，不包含本地备注。

## 列表刷新

手机与窄屏 Web 支持下拉刷新，桌面与宽屏 Web 提供标题栏刷新按钮。空态、少量联系人和错误态也应可刷新；多个刷新入口等待同一个进行中的 Future，避免重复请求。

刷新保留既有数据，失败时保留重试入口。首次加载、缓存与错误状态约定见 [聊天与联系人加载状态](./chat_loading_states.md)。
