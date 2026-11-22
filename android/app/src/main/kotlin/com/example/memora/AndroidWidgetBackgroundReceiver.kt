package com.example.memora

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.Operation
import androidx.work.WorkManager
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import io.flutter.FlutterInjector

class AndroidWidgetBackgroundReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val uri = intent.data ?: return
        val applicationContext = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        enqueue(applicationContext, uri)
    }

    companion object {
        internal fun enqueue(context: Context, uri: Uri): Operation {
            // home_widgetのWorkerと同じ入力形式・キュー名を使い、失敗した依存だけを引き継がない。
            val request = OneTimeWorkRequestBuilder<HomeWidgetBackgroundWorker>()
                .setInputData(Data.Builder().putString("uri_data", uri.toString()).build())
                .build()
            val automaticCalendarRefresh = uri.host.equals("calendarRefresh", ignoreCase = true) &&
                uri.getQueryParameter("automatic") == "true"
            val (workName, policy) = if (automaticCalendarRefresh) {
                "memora_calendar_automatic_refresh" to ExistingWorkPolicy.KEEP
            } else {
                "home_widget_background" to ExistingWorkPolicy.APPEND_OR_REPLACE
            }
            return WorkManager.getInstance(context).enqueueUniqueWork(workName, policy, request)
        }

        fun request(context: Context, uri: Uri) {
            context.sendBroadcast(
                Intent(context, AndroidWidgetBackgroundReceiver::class.java).setData(uri),
            )
        }
    }
}
