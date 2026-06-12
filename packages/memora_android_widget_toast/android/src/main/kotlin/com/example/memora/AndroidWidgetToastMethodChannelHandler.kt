package com.example.memora

import android.content.Context
import android.widget.Toast
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AndroidWidgetToastMethodChannelHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showToast" -> showToast(call, result)
            else -> result.notImplemented()
        }
    }

    private fun showToast(call: MethodCall, result: MethodChannel.Result) {
        val message = call.argument<String>("message").orEmpty()
        if (message.isBlank()) {
            result.success(null)
            return
        }

        Toast.makeText(context.applicationContext, message, Toast.LENGTH_SHORT).show()
        result.success(null)
    }

    companion object {
        const val CHANNEL = "memora/android_widget_toast"
    }
}
