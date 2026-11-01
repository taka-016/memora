package com.example.memora

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import es.antonborri.home_widget.HomeWidgetLaunchIntent

internal fun widgetListLaunchIntent(context: Context, widgetId: Int): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
    }
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= 31) {
        PendingIntent.FLAG_MUTABLE
    } else {
        0
    }
    val options = if (Build.VERSION.SDK_INT >= 34) {
        ActivityOptions.makeBasic().apply {
            if (Build.VERSION.SDK_INT >= 35) {
                setPendingIntentCreatorBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                )
            } else {
                pendingIntentBackgroundActivityStartMode =
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
            }
        }.toBundle()
    } else {
        null
    }
    return PendingIntent.getActivity(context, widgetId, intent, flags, options)
}
