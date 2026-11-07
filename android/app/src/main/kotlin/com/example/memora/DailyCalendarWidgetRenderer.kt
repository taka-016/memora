package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.format.DateTimeFormatter
import java.util.Locale

internal object DailyCalendarWidgetRenderer {
    private val dateFormat = DateTimeFormatter.ofPattern("M月d日(E)", Locale.JAPANESE)

    fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val appearance = WidgetAppearance.forWidget(manager, widgetId)
        val views = RemoteViews(context.packageName, appearance.dailyCalendarLayout)
        val groupId = CalendarWidgetData.targetGroup(context)
        val cache = CalendarWidgetData.read(context)
        val selected = CalendarWidgetData.selectedDate(context, widgetId)
        val month = cache?.let { CalendarWidgetData.readMonth(context, it, selected.withDayOfMonth(1)) }
        val configured = groupId.isNotEmpty()
        views.setViewVisibility(R.id.calendar_content, if (configured) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.calendar_message, if (configured) View.GONE else View.VISIBLE)
        views.setOnClickPendingIntent(R.id.calendar_message, HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("memoraWidget://openSettings"),
        ))
        val settings = CalendarWidgetDisplaySettings.read(context)
        val day = month?.days?.firstOrNull { it.date == selected }
        val dateText = calendarWidgetDateLabel(selected.format(dateFormat), day, settings)
        val color = (day ?: CalendarWidgetDay(selected, emptyList())).dateColor(appearance)
        views.setTextViewText(R.id.calendar_selected_date, dateText)
        views.setTextViewText(R.id.daily_compact_date, dateText)
        views.setTextColor(R.id.calendar_selected_date, color)
        views.setTextColor(R.id.daily_compact_date, color)
        views.setOnClickPendingIntent(R.id.daily_compact_date, HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, calendarLaunchUri(groupId, selected),
        ))
        views.setOnClickPendingIntent(R.id.daily_compact_refresh, calendarWidgetAction(context, widgetId))
        views.setOnClickPendingIntent(R.id.calendar_today, calendarWidgetAction(context, widgetId, today = true))
        views.setOnClickPendingIntent(R.id.calendar_previous, calendarWidgetAction(context, widgetId, selected.minusDays(1)))
        views.setOnClickPendingIntent(R.id.calendar_next, calendarWidgetAction(context, widgetId, selected.plusDays(1)))
        views.setOnClickPendingIntent(R.id.calendar_selected_date, HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, calendarLaunchUri(groupId, selected),
        ))
        views.setOnClickPendingIntent(R.id.calendar_add, HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, calendarLaunchUri(groupId, selected, create = true),
        ))
        views.setOnClickPendingIntent(R.id.calendar_refresh, calendarWidgetAction(context, widgetId))
        val loadState = CalendarWidgetData.loadState(context, selected)
        views.setTextViewText(R.id.calendar_empty, if (month == null) loadState.message else "予定はありません")
        views.setOnClickPendingIntent(R.id.calendar_empty, if (month == null && loadState.canRetry) {
            calendarWidgetAction(context, widgetId, selected)
        } else null)
        views.setEmptyView(R.id.calendar_events, R.id.calendar_empty)
        views.setPendingIntentTemplate(R.id.calendar_events, widgetListLaunchIntent(context, widgetId))
        if (Build.VERSION.SDK_INT >= 31) {
            val items = RemoteViews.RemoteCollectionItems.Builder()
                .setHasStableIds(false).setViewTypeCount(1)
            calendarWidgetEventsForDate(month, selected).forEachIndexed { index, event ->
                items.addItem(index.toLong(), calendarEventRow(
                    context, groupId, selected, event, appearance, daily = true,
                ))
            }
            views.setRemoteAdapter(R.id.calendar_events, items.build())
        } else {
            val adapter = Intent(context, CalendarWidgetListService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("memoraCalendar://dailyList/$widgetId")
            }
            views.setRemoteAdapter(R.id.calendar_events, adapter)
        }
        views.setScrollPosition(R.id.calendar_events, 0)
        val updated = cache?.lastUpdatedAt.orEmpty().replace("-", "/").replace("T", " ").take(16)
        views.setTextViewText(R.id.calendar_last_updated, if (updated.isBlank()) "" else "最終更新 $updated")
        val options = manager.getAppWidgetOptions(widgetId)
        val portrait = copyViews(views)
        val landscape = copyViews(views)
        resize(context, portrait, options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110))
        resize(context, landscape, options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 110))
        manager.updateAppWidget(widgetId, RemoteViews(landscape, portrait))
        if (Build.VERSION.SDK_INT < 31) {
            manager.notifyAppWidgetViewDataChanged(widgetId, R.id.calendar_events)
        }
    }

    @Suppress("DEPRECATION")
    private fun copyViews(views: RemoteViews): RemoteViews =
        if (Build.VERSION.SDK_INT >= 28) RemoteViews(views) else views.clone()

    private fun resize(context: Context, views: RemoteViews, width: Int) {
        val compact = width < 220
        views.setTextViewTextSize(
            R.id.calendar_today, android.util.TypedValue.COMPLEX_UNIT_SP,
            if (compact) 13f else 16f,
        )
        val headerHeight = if (compact) 40 else 48
        views.setInt(
            R.id.daily_navigation, "setMinimumHeight",
            (headerHeight * context.resources.displayMetrics.density).toInt(),
        )
        views.setViewVisibility(R.id.daily_compact_header, if (compact) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.calendar_selected_date, if (compact) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.daily_footer, if (compact) View.GONE else View.VISIBLE)
    }
}
