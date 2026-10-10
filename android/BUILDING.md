# Android 构建说明

从客户端根目录运行 `./tool_build.ps1 -Target android`，依次生成 Dart 协议、解析依赖、运行 wire 回归测试、构建 release APK。

## 构建工具

- Gradle 9.1.0（wrapper 固定版本并验证 SHA-256）。
- Android Gradle Plugin 9.0.1；`settings.gradle.kts` 与根 `build.gradle.kts` 的声明必须同步。
- Kotlin Gradle Plugin 2.3.20；应用与 Android 插件统一编译为 JVM 17。
- `android.builtInKotlin=false` 与 `android.newDsl=false` 保留旧插件兼容模式。迁移所有 Flutter 和华为插件后再移除，不能单独开启。
- 极光 Flutter 插件固定 3.5.8，其 Android JPush SDK 与应用中的华为通道依赖均为 6.2.1。旧插件 3.4.6 的 `jcenter()` 调用不兼容 Gradle 9。
- `file_picker 11.0.2` 在 AGP 9 下无条件跳过 KGP；根构建脚本在关闭内置 Kotlin 时为它补充 KGP，否则 `FilePickerPlugin` 不会被编译。上游修复判断后可移除此补丁。

## 警告处理

- `cupertino_icons` 提供 Flutter 或第三方组件引用的 Cupertino 图标字体。
- Android library 的 Java 版本在 `finalizeDsl` 中统一，避免被插件自身的 Java 8 配置覆盖。
- `audio_waveforms 2.0.2` 仍引入 ExoPlayer 2.17.1，可能产生 AndroidX/support 混用提示；保留 Jetifier，待插件迁移或经过音频播放验证后再替换依赖。
- `pip` 等第三方插件的过时 API、未经检查操作提示，需要上游修复或单独维护补丁；不要直接修改 Pub 缓存或全局关闭编译诊断。
- AGP 9 兼容模式下 Flutter 会提示应用和部分插件仍使用 Kotlin Gradle Plugin；这是后续内置 Kotlin 迁移任务，升级版本号无法解决。
- 图标 tree shaking 和 Flutter 镜像下载源提示属于正常输出。

升级后除 release 打包外，还应在真机检查语音录制/播放、画中画及推送通知（含华为通道冷启动点击）。
