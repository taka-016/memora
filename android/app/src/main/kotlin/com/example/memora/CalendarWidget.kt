package com.example.memora

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate

internal const val CALENDAR_SELECT_ACTION = "com.example.memora.action.CALENDAR_SELECT"
internal const val CALENDAR_REFRESH_ACTION = "com.example.memora.action.CALENDAR_REFRESH"
private const val CALENDAR_DATE_EXTRA = "date"
private const val CALENDAR_TODAY_EXTRA = "today"

open class CalendarWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        widgetIds.forEach { CalendarWidgetRenderer.update(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        newOptions: Bundle,
    ) {
        CalendarWidgetRenderer.update(context, manager, widgetId, forceFull = true)
    }

    override fun onDeleted(context: Context, widgetIds: IntArray) {
        widgetIds.forEach {
            CalendarWidgetData.forgetWidget(context, it)
            CalendarWidgetRenderer.forget(it)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            CALENDAR_SELECT_ACTION -> selectDate(context, intent)
            CALENDAR_REFRESH_ACTION -> {
                val widgetId = widgetId(intent)
                if (!isCalendarWidget(context, widgetId)) return
                CalendarWidgetData.selectDate(
                    context, widgetId, CalendarWidgetData.selectedDate(context, widgetId),
                )
                requestCalendarRefresh(context)
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                if (!intent.getBooleanExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, false)) {
                    AndroidWidgetUpdateFallbackScheduler.schedule(context)
                    AndroidWidgetUpdateFallbackScheduler.recoverIfOverdue(context)
                    requestCalendarRefresh(context)
                }
            }
        }
    }

    private fun selectDate(context: Context, intent: Intent) {
        val widgetId = widgetId(intent)
        if (!isCalendarWidget(context, widgetId)) return
        val date = if (intent.getBooleanExtra(CALENDAR_TODAY_EXTRA, false)) {
            LocalDate.now()
        } else {
            runCatching {
                LocalDate.parse(intent.getStringExtra(CALENDAR_DATE_EXTRA))
            }.getOrNull() ?: return
        }
        val previous = CalendarWidgetData.selectedDate(context, widgetId)
        val month = date.withDayOfMonth(1)
        val months = CalendarWidgetData.read(context)?.months.orEmpty()
        CalendarWidgetData.selectDate(context, widgetId, date)
        CalendarWidgetRenderer.update(context, AppWidgetManager.getInstance(context), widgetId)
        val missingNeighbor = !months.containsKey(month.minusMonths(1)) ||
            !months.containsKey(month.plusMonths(1))
        if (!months.containsKey(month) ||
            (previous.withDayOfMonth(1) != month && missingNeighbor)) {
            requestCalendarRefresh(context, date)
        }
    }

    private fun isCalendarWidget(context: Context, widgetId: Int): Boolean =
        AppWidgetManager.getInstance(context).getAppWidgetInfo(widgetId)?.provider?.className
            .let { it == CalendarWidgetReceiver::class.java.name || it == CalendarDarkWidgetReceiver::class.java.name }

    private fun widgetId(intent: Intent): Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
    )
}

internal fun calendarWidgetAction(
    context: Context,
    widgetId: Int,
    date: LocalDate? = null,
    today: Boolean = false,
): PendingIntent {
    val action = if (date != null || today) CALENDAR_SELECT_ACTION else CALENDAR_REFRESH_ACTION
    val intent = Intent(context, CalendarWidgetReceiver::class.java).apply {
        component = AppWidgetManager.getInstance(context).getAppWidgetInfo(widgetId)?.provider
        this.action = action
        data = Uri.Builder().scheme("memoraCalendar").authority("action")
            .appendPath(widgetId.toString())
            .appendPath(if (today) "today" else date?.toString() ?: "refresh").build()
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        if (date != null) putExtra(CALENDAR_DATE_EXTRA, date.toString())
        if (today) putExtra(CALENDAR_TODAY_EXTRA, true)
        addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
    }
    return PendingIntent.getBroadcast(
        context, widgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

private fun requestCalendarRefresh(context: Context, date: LocalDate? = null) {
    HomeWidgetBackgroundIntent.getBroadcast(context,
        Uri.parse("memoraWidget://calendarRefresh?date=${date?.toString().orEmpty()}")).send()
}
