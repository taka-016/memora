package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context
import java.time.LocalDate

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

internal fun dailyCalendarEvents(month: CalendarWidgetMonth?, date: LocalDate): List<CalendarWidgetEvent> =
    month?.days?.firstOrNull { it.date == date }?.events
        .orEmpty().sortedWith(calendarWidgetEventOrder)
