package cn.anoxia.notepadclient

import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opentraa.pip.PipActivity

class MainActivity : PipActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL_NAME = "pip"
    }

    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 注册 Flutter 通信
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )
    }

    /**
     * PiP 状态变化回调
     *
     * 新版 flutter_pip 已经移除了 mPipController 字段，
     * 所以不能再使用反射访问内部实现。
     *
     * 这里只做：
     * 1. 安全调用 super
     * 2. 手动通知 Flutter
     * 3. 防止第三方插件内部异常导致闪退
     */
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {

        // 先安全调用父类
        try {
            super.onPictureInPictureModeChanged(
                isInPictureInPictureMode,
                newConfig
            )
        } catch (e: Exception) {
            Log.e(
                TAG,
                "PipActivity callback error",
                e
            )
        }

        // 手动同步 PiP 状态给 Flutter
        try {
            if (::channel.isInitialized) {
                channel.invokeMethod(
                    "onPictureInPictureModeChanged",
                    isInPictureInPictureMode
                )

                Log.d(
                    TAG,
                    "PiP state changed: $isInPictureInPictureMode"
                )
            }
        } catch (e: Exception) {
            Log.e(
                TAG,
                "Failed to notify Flutter PiP state",
                e
            )
        }
    }
}