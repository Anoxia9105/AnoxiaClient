# 更新下载恢复

Android 切到后台、锁屏时暂停应用内更新下载，保留当前任务的已下载字节；收到 `resumed` 后恢复。`inactive`（通知栏、系统弹窗等中间状态）不会提前恢复已暂停的任务。此机制不依赖后台常驻服务，不保证进程被系统终止后继续下载。

安装包通过独立 HTTP 连接下载。服务器提供强 ETag 或 Last-Modified 时，使用 Range / If-Range 在同一任务内续传；没有校验标识或服务器返回完整响应时从头覆盖，避免错误拼接。416 最多回退重下一次。连接中断、超时及临时服务端错误最多自动重试三次，404 等明确错误直接显示失败。

下载完成后仍检查字节数及服务端提供的 SHA-256。重试、切换版本或 reset 会取消旧任务，并等待文件关闭；旧任务不得覆盖当前下载状态。

回归测试：`flutter test test/framework/network/update_package_downloader_test.dart test/framework/provider/update_download_provider_test.dart test/features/update`。其中真实本地 HTTP 服务器覆盖锁屏恢复、连续挂起、忽略 Range、断连重试、后台取消、有限重试和版本切换竞争；生命周期使用 Flutter 测试绑定模拟，设备省电策略仍需真机验证。

手动暂停和系统后台暂停分别记录：用户主动暂停后，即使锁屏再回前台也不会自动恢复，必须点击继续下载。同一任务暂停后保持下载文件与校验标识，不创建第二个下载。关于页同步显示下载、暂停、失败和待安装状态。强制更新仍限制跳过，但也要用户确认后才会启动安装器。

界面适配与交互回归：`flutter test test/features/settings/about_support_layout_test.dart test/features/settings/settings_about_navigation_test.dart test/features/update`，覆盖 PC/SP、深浅主题、中英日三语言、大字体、反馈跳转与安装确认。设计参考：`design/about-support.html`。
