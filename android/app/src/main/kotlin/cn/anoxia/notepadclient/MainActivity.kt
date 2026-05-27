package cn.anoxia.notepadclient

import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import org.opentraa.pip.PipActivity // 引入 PipActivity

class MainActivity : PipActivity() {
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 注册 MethodChannel，用于手动发送 PiP 状态变化
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pip")
    }

    /**
     * 重写 onPictureInPictureModeChanged 以防止 NullPointerException
     * 
     * 问题根源：org.opentraa.pip 插件的 PipController.mPipParams 在某些情况下未初始化，
     * 导致 onPictureInPictureModeChanged 回调时触发空指针异常。
     * 
     * 解决方案：在调用父类方法前，通过反射检查并初始化 mPipParams。
     */
    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: android.content.res.Configuration) {
        try {
            // ⚠️ 核心修复：在调用父类方法前，确保 mPipParams 已初始化
            ensurePipParamsInitialized()
            
            // 安全调用父类方法
            super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        } catch (e: NullPointerException) {
            // 精确拦截由第三方插件底层在回调中引发的空指针异常
            android.util.Log.e("MainActivity", "🔥 成功拦截第三方 Pip 插件在生命周期回调中的空指针闪退", e)
            
            // ⚠️ 关键修复：即使发生异常，也要手动通知 Flutter 端 PiP 状态变化
            try {
                if (::channel.isInitialized) {
                    channel.invokeMethod("onPictureInPictureModeChanged", isInPictureInPictureMode)
                    android.util.Log.i("MainActivity", "📤 手动发送 PiP 状态到 Flutter: $isInPictureInPictureMode")
                }
            } catch (channelEx: Exception) {
                android.util.Log.e("MainActivity", "Failed to send PiP state to Flutter", channelEx)
            }
        } catch (e: Exception) {
            // 兜底其他未知异常
            android.util.Log.e("MainActivity", "Unexpected error in PiP callback", e)
        }
    }

    /**
     * 确保 PipController 的 mPipParams 字段已初始化
     * 
     * 通过反射检查并初始化，防止 onPictureInPictureModeChanged 回调时触发 NPE。
     */
    private fun ensurePipParamsInitialized() {
        try {
            // 获取 PipActivity 的 mPipController 字段
            val pipControllerField = PipActivity::class.java.getDeclaredField("mPipController")
            pipControllerField.isAccessible = true
            val pipController = pipControllerField.get(this) ?: return

            // 获取 PipController 的 mPipParams 字段
            val pipParamsField = pipController.javaClass.getDeclaredField("mPipParams")
            pipParamsField.isAccessible = true
            val pipParams = pipParamsField.get(pipController)

            // 如果 mPipParams 为 null，创建默认参数并设置
            if (pipParams == null) {
                android.util.Log.w("MainActivity", "⚠️ mPipParams 为 null，正在初始化默认参数")
                
                // 获取 PipParams 类
                val pipParamsClass = Class.forName("org.opentraa.pip.PipController\$PipParams")
                val constructor = pipParamsClass.getDeclaredConstructor()
                constructor.isAccessible = true
                
                // 创建 PipParams 实例
                val newPipParams = constructor.newInstance()
                
                // 设置默认值（使用反射设置字段）
                setFieldValue(newPipParams, "useExternalStateMonitor", false)
                setFieldValue(newPipParams, "seamlessResizeEnabled", false)
                setFieldValue(newPipParams, "autoEnterEnabled", true)
                setFieldValue(newPipParams, "aspectRatioX", 9)
                setFieldValue(newPipParams, "aspectRatioY", 16)
                setFieldValue(newPipParams, "controlStyle", 2)
                
                // 设置回 PipController
                pipParamsField.set(pipController, newPipParams)
                android.util.Log.i("MainActivity", "✅ mPipParams 初始化成功")
            }
        } catch (e: Exception) {
            // 反射操作可能失败（如混淆等），这里不抛异常，让上层处理
            android.util.Log.e("MainActivity", "Failed to ensure mPipParams initialized", e)
        }
    }

    /**
     * 使用反射设置对象字段值
     */
    private fun setFieldValue(obj: Any, fieldName: String, value: Any) {
        try {
            val field = obj.javaClass.getDeclaredField(fieldName)
            field.isAccessible = true
            field.set(obj, value)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to set field $fieldName", e)
        }
    }
}