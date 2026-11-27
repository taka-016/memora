package io.github.taka016.memora

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AndroidWidgetUpdateFallbackReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in SUPPORTED_ACTIONS) {
            return
        }
        AndroidWidgetUpdateFallbackScheduler.schedule(context)
        AndroidWidgetUpdateFallbackScheduler.recoverIfOverdue(context)
    }

    companion object {
        const val ACTION_CHECK =
            "io.github.taka016.memora.action.CHECK_ANDROID_WIDGET_UPDATE"

        private val SUPPORTED_ACTIONS = setOf(
            ACTION_CHECK,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )
    }
}
