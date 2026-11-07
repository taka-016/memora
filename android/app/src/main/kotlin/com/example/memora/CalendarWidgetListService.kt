package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.time.LocalDate

class CalendarWidgetListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = CalendarEventsFactory(
        applicationContext,
        intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID),
    )
}

private class CalendarEventsFactory(
    private val context: Context,
    private val widgetId: Int,
) : RemoteViewsService.RemoteViewsFactory {
    private data class Snapshot(
        val groupId: String,
        val date: LocalDate,
        val events: List<CalendarWidgetEvent>,
    )

    private var snapshot = Snapshot("", LocalDate.now(), emptyList())

    override fun onCreate() {
        onDataSetChanged()
    }

    override fun onDataSetChanged() {
        val date = CalendarWidgetData.selectedDate(context, widgetId)
        val cache = CalendarWidgetData.read(context)
        val month = cache?.let { CalendarWidgetData.readMonth(context, it, date.withDayOfMonth(1)) }
        val events = calendarWidgetEventsForDate(month, date)
        snapshot = Snapshot(cache?.groupId.orEmpty(), date, events)
    }

    override fun getViewAt(position: Int): RemoteViews? {
        val current = snapshot
        val event = current.events.getOrNull(position) ?: return null
        return calendarEventRow(
            context, current.groupId, current.date, event,
            WidgetAppearance.forWidget(AppWidgetManager.getInstance(context), widgetId),
            daily = isDailyCalendarWidget(AppWidgetManager.getInstance(context), widgetId),
        )
    }

    override fun getCount(): Int = snapshot.events.size
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
    override fun getViewTypeCount(): Int = 1
    override fun getLoadingView(): RemoteViews? = null
    override fun onDestroy() {
        snapshot = snapshot.copy(events = emptyList())
    }
}

internal fun calendarEventRow(
    context: Context,
    groupId: String,
    date: LocalDate,
    event: CalendarWidgetEvent,
    appearance: WidgetAppearance,
    daily: Boolean = false,
): RemoteViews = RemoteViews(context.packageName, if (daily) {
    appearance.dailyCalendarEventLayout
} else {
    appearance.calendarEventLayout
}).apply {
    val times = event.timeLabel.split('–', limit = 2)
    val hasEnd = !event.isAllDay && times.size == 2
    setTextViewText(R.id.calendar_event_start, times[0])
    setTextViewText(R.id.calendar_event_end, times.getOrElse(1) { "" })
    setViewVisibility(R.id.calendar_event_separator, if (hasEnd) View.VISIBLE else View.GONE)
    setViewVisibility(R.id.calendar_event_end, if (hasEnd) View.VISIBLE else View.GONE)
    setInt(R.id.calendar_event_bar, "setBackgroundColor", event.color)
    setTextViewText(R.id.calendar_event_title, event.title)
    setOnClickFillInIntent(R.id.calendar_event_row, Intent().apply {
        data = calendarLaunchUri(groupId, date).buildUpon()
            .apply {
                event.openEventId?.let { id ->
                    appendQueryParameter("eventId", id)
                    event.occurrence?.let { appendQueryParameter("occurrence", it) }
                }
            }
            .build()
    })
}
