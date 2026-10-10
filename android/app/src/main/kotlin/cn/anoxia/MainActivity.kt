package cn.anoxia

import android.content.res.Configuration
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opentraa.pip.PipActivity

class MainActivity : PipActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val PIP_CHANNEL_NAME = "pip"
        private const val SCREEN_CHANNEL_NAME = "screen_control"
        private const val APP_NAVIGATION_CHANNEL_NAME = "app_navigation"
    }

    private lateinit var pipChannel: MethodChannel

    // 根路由也由 Flutter 接收系统返回，避免预测性返回绕过 popSystemNavigator
    // 直接销毁 Activity；子页面仍使用 Flutter 自带的返回手势与路由处理。
    override fun setFrameworkHandlesBack(frameworkHandlesBack: Boolean) {
        super.setFrameworkHandlesBack(true)
    }

    // Flutter 先处理页面、弹窗的返回；只有路由栈已无法返回才到这里。
    // 保留 Activity 和 FlutterEngine，返回桌面后再打开可继续当前会话。
    override fun popSystemNavigator(): Boolean {
        moveTaskToBack(true)
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 显式「退出应用」与系统返回分开，保留强制更新页的退出语义。
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_NAVIGATION_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "exitApp" -> {
                    result.success(null)
                    finish()
                }
                else -> result.notImplemented()
            }
        }

        // pip channel 不注册 handler，让 pip 插件自己用
        pipChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PIP_CHANNEL_NAME
        )

        // 屏幕常亮独立 channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepScreenOn" -> {
                    val on = call.arguments as Boolean
                    if (on) {
                        window.addFlags(
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        )
                    } else {
                        window.clearFlags(
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        )
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        try {
            super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        } catch (e: Exception) {
            Log.e(TAG, "PipActivity callback error", e)
        }

        try {
            if (::pipChannel.isInitialized) {
                pipChannel.invokeMethod(
                    "onPictureInPictureModeChanged",
                    isInPictureInPictureMode
                )
                Log.d(TAG, "PiP state changed: $isInPictureInPictureMode")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify Flutter PiP state", e)
        }
    }

    override fun onUserLeaveHint() {
        try {
            super.onUserLeaveHint()
        } catch (e: Exception) {
            // pip 0.0.3 在部分时序下（如系统权限弹窗触发 Activity 暂停）
            // 会因为内部参数尚未初始化而抛 NPE，这里兜底避免主线程崩溃。
            Log.e(TAG, "PipActivity onUserLeaveHint error", e)
        }
    }
}
