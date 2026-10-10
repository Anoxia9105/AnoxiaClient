# Android 返回行为

Android 返回先交给 Flutter 路由：关闭键盘、弹窗或当前子页面；根路由无法返回时，由 `MainActivity.popSystemNavigator()` 调用 `moveTaskToBack(true)` 并消费返回事件，保留 Activity 和 FlutterEngine。不要在 `onBackPressed()` 中无条件退到后台，否则聊天详情页也无法正常返回。

Manifest 开启 `enableOnBackInvokedCallback`，由 Flutter 处理新系统的预测性返回。强制更新页的「退出应用」通过 `app_navigation/exitApp` 显式调用 `finish()`，与根页面返回分开。

新 Android 在根路由默认会注销 Flutter 返回回调，系统返回因而可能直接销毁 Activity，绕过 `popSystemNavigator()`。`setFrameworkHandlesBack()` 保持 Flutter 回调注册，让根路由的系统返回同样走后台化逻辑；Activity 销毁时仍由 Flutter 解除注册。

后台化不是后台保活承诺；Android 仍可能按内存、电池和后台策略回收进程，消息推送与重连机制仍需正常工作。

## 验证

自动回归：

```powershell
flutter test test/features/app/android_back_navigation_test.dart test/features/update/update_page_test.dart
```

原生实测入口使用真实 MainActivity，避免依赖业务账号和网络：

```powershell
../AnoxiaProtocol/tool_generate_dart.ps1
flutter test test/framework/codec/im_packet_v6_test.dart
flutter build apk --debug -t test/support/android_back_smoke_app.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell am start -W -n cn.anoxia/.MainActivity
```

验收：输入草稿，返回先收起键盘；进入 Detail 后返回到首页；打开 Dialog 后返回关闭弹窗；首页返回或点击 Root back 后桌面可见，Activity 不被销毁；重开应用后进程 PID、Activity 标识和草稿不变；Explicit exit 后 Activity 被销毁。手势导航还需检查返回手势提交与取消。

这是专用验证包，不能作为业务 APK 发布。验证结束后用 `./tool_build.ps1 -Target android -Debug` 恢复正常应用构建。

### 2026-10-10 验证记录

- Flutter 全量回归：243 项通过、1 项跳过；返回和强制更新退出的两项定向回归再次通过。
- 本次修改的 Dart 文件静态检查通过，Android 原生验证包构建通过。
- Android 37 / Pixel 9 模拟器：返回先关闭键盘、子页面或弹窗；根页面系统返回、完成的边缘返回手势及 `SystemNavigator.pop()` 均转入后台，重开后 Activity 标识、进程 PID 和草稿保持一致；Explicit exit 最终销毁 Activity。
- 验证脚本等待系统转场完成再断言，避免把异步后台化或 `finish()` 的中间状态判为失败。弹窗关闭后若键盘恢复，先关闭键盘再验证根页面返回。
- 以上是使用真实 MainActivity 的隔离测试入口，未验证真实聊天服务的后台收消息；真机、旧版 Android 和取消返回手势仍需补充覆盖。

参考：[FlutterActivity 返回扩展点](https://api.flutter.dev/javadoc/io/flutter/embedding/android/FlutterActivity.html#popSystemNavigator())、[Flutter 预测性返回](https://docs.flutter.dev/platform-integration/android/predictive-back)。
