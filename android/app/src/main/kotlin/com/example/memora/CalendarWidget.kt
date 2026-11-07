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
import java.util.concurrent.Executors

internal const val CALENDAR_SELECT_ACTION = "com.example.memora.action.CALENDAR_SELECT"
internal const val CALENDAR_REFRESH_ACTION = "com.example.memora.action.CALENDAR_REFRESH"
private const val CALENDAR_DATE_EXTRA = "date"
private const val CALENDAR_TODAY_EXTRA = "today"

open class CalendarWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        widgetIds.forEach { updateWidget(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, manager, widgetId, forceFull = true)
    }

    protected open fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        forceFull: Boolean = false,
    ) {
        CalendarWidgetRenderer.update(context, manager, widgetId, forceFull)
    }

    override fun onDeleted(context: Context, widgetIds: IntArray) {
        widgetIds.forEach {
            CalendarWidgetData.forgetWidget(context, it)
            CalendarWidgetRenderer.forget(it)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        updates.execute {
            try {
                receive(context, intent)
            } finally {
                pending.finish()
            }
        }
    }

    private fun receive(context: Context, intent: Intent) {
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE &&
            !intent.getBooleanExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, false)) {
            intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)?.forEach { widgetId ->
                CalendarWidgetData.startLoading(context, CalendarWidgetData.selectedDate(context, widgetId))
            }
        }
        super.onReceive(context, intent)
        when (intent.action) {
            CALENDAR_SELECT_ACTION -> selectDate(context, intent)
            CALENDAR_REFRESH_ACTION -> {
                val widgetId = widgetId(intent)
                if (!isCalendarWidget(context, widgetId)) return
                CalendarWidgetData.selectDate(
                    context, widgetId, CalendarWidgetData.selectedDate(context, widgetId),
                )
                CalendarWidgetData.startLoading(context, CalendarWidgetData.selectedDate(context, widgetId))
                updateWidget(context, AppWidgetManager.getInstance(context), widgetId)
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
        val missingNeighbor = !months.containsKey(month.minusMonths(1)) ||
            !months.containsKey(month.plusMonths(1))
        val needsRefresh = !months.containsKey(month) ||
            (previous.withDayOfMonth(1) != month && missingNeighbor)
        if (needsRefresh) CalendarWidgetData.startLoading(context, date)
        updateWidget(context, AppWidgetManager.getInstance(context), widgetId)
        if (needsRefresh) requestCalendarRefresh(context, date)
    }

    private fun isCalendarWidget(context: Context, widgetId: Int): Boolean =
        AppWidgetManager.getInstance(context).getAppWidgetInfo(widgetId)?.provider?.className
            .let { provider ->
                provider == CalendarWidgetReceiver::class.java.name ||
                    provider == CalendarDarkWidgetReceiver::class.java.name ||
                    provider == DailyCalendarWidgetReceiver::class.java.name ||
                    provider == DailyCalendarDarkWidgetReceiver::class.java.name
            }

    companion object {
        private val updates = Executors.newSingleThreadExecutor()
    }

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
