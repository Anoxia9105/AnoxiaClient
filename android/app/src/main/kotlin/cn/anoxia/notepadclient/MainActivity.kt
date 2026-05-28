package cn.anoxia.notepadclient

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
    }

    private lateinit var pipChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
}