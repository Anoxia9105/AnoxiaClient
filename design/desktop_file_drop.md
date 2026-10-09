# 桌面聊天文件拖放

Windows / macOS / Linux 的正常聊天房间支持从文件管理器拖入文件。拖放区域覆盖聊天消息区和输入框；松手后插入现有 Quill 草稿并后台上传，用户确认后点击发送。图片、视频和普通文件沿用已有分类、预览、上传进度、重试和发送链路。

拖入时显示跟随主题的提示遮罩，不抢输入焦点；拖出后隐藏。准备附件时显示进度。文件夹、丢失文件及不可读文件提示并跳过，不递归上传；同一批次的重复路径只添加一次。数量及体积限制沿用 UploadValidator：包含草稿已有附件，最多 10 件、单个 50 MB、总计 100 MB。

官方房间、初始化中、禁言、封禁、解散、弹窗覆盖及非桌面平台不接收拖放。读取文件及图片元数据期间切换房间或销毁页面，会取消未插入的批次；已进入草稿的附件沿用现有上传生命周期。

实现入口：`DesktopChatDropTarget` 接收 desktop_drop 原生事件，`prepareDesktopDropFiles` 校验本地路径，`ChatFileUploadController.insertPickedFiles` 与文件选择按钮共用附件逻辑。原生文件只传路径，避免预读大文件；文件读取通过条件导出隔离。

上传时使用 `isLocalMediaFilePath` 区分磁盘路径与 `local-pending://` / `blob:` 占位地址；`isPendingLocalMediaUrl` 表示尚未成为服务器资源，不能用来排除可上传的本地文件。文件和视频失败卡片提供真正的重试按钮，复用原附件 ID 与本地源；上传中忽略重复重试。批量插入后逐个登记编辑器归属，避免文档监听提前清理尚未插入的附件。

macOS 沙箱增加 `com.apple.security.files.user-selected.read-only`，仅允许读取用户主动选择或拖入的文件。[Apple 沙箱文件访问文档](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)

自动验证：

```sh
flutter test test/features/chat/desktop_drop_files_test.dart test/features/chat/desktop_chat_drop_target_test.dart test/features/chat/desktop_drop_upload_test.dart
flutter test test/features/chat/desktop_upload_multipart_test.dart test/features/chat/file_embed_retry_test.dart
flutter analyze
```

桌面验收：从文件管理器分别拖入图片、视频、普通文件及混合批次；确认遮罩覆盖输入框、预览/进度正确且不自动发送；上传后发送并检查接收端。再检查拖出取消、文件夹、大小/数量超限、上传失败、切换房间、弹窗覆盖、深浅色和高 DPI。新增原生插件后必须完整重启应用，不能只热重载。
