package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context

open class DailyCalendarWidgetReceiver : CalendarWidgetReceiver() {
    override fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        forceFull: Boolean,
    ) {
        DailyCalendarWidgetRenderer.update(context, manager, widgetId)
    }
}

class DailyCalendarDarkWidgetReceiver : DailyCalendarWidgetReceiver()

internal fun isDailyCalendarWidget(manager: AppWidgetManager, widgetId: Int): Boolean =
    manager.getAppWidgetInfo(widgetId)?.provider?.className.let {
        it == DailyCalendarWidgetReceiver::class.java.name ||
            it == DailyCalendarDarkWidgetReceiver::class.java.name
    }
