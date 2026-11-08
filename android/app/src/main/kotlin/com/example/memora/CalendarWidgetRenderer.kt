package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

internal object CalendarWidgetRenderer {
    private data class Size(val width: Int, val height: Int)
    private data class Sizes(val portrait: Size, val landscape: Size)
    private data class RenderedState(
        val groupId: String,
        val month: CalendarWidgetMonth,
        val loaded: Boolean,
        val loadState: WidgetLoadState,
        val sizes: Sizes,
        val today: LocalDate,
        val selected: LocalDate,
        val lastUpdatedAt: String,
        val appearance: WidgetAppearance,
        val settings: CalendarWidgetDisplaySettings,
    )
    private data class MonthViews(val portrait: RemoteViews, val landscape: RemoteViews)

    private val states = mutableMapOf<Int, RenderedState>()
    private val monthViews = mutableMapOf<Int, MonthViews>()
    private val dateFormat = DateTimeFormatter.ofPattern("M月d日（E）", Locale.JAPANESE)
    private val dayIds = intArrayOf(
        R.id.calendar_day_0, R.id.calendar_day_1, R.id.calendar_day_2,
        R.id.calendar_day_3, R.id.calendar_day_4, R.id.calendar_day_5, R.id.calendar_day_6,
        R.id.calendar_day_7, R.id.calendar_day_8, R.id.calendar_day_9,
        R.id.calendar_day_10, R.id.calendar_day_11, R.id.calendar_day_12, R.id.calendar_day_13,
        R.id.calendar_day_14, R.id.calendar_day_15, R.id.calendar_day_16,
        R.id.calendar_day_17, R.id.calendar_day_18, R.id.calendar_day_19, R.id.calendar_day_20,
        R.id.calendar_day_21, R.id.calendar_day_22, R.id.calendar_day_23,
        R.id.calendar_day_24, R.id.calendar_day_25, R.id.calendar_day_26, R.id.calendar_day_27,
        R.id.calendar_day_28, R.id.calendar_day_29, R.id.calendar_day_30,
        R.id.calendar_day_31, R.id.calendar_day_32, R.id.calendar_day_33, R.id.calendar_day_34,
        R.id.calendar_day_35, R.id.calendar_day_36, R.id.calendar_day_37,
        R.id.calendar_day_38, R.id.calendar_day_39, R.id.calendar_day_40, R.id.calendar_day_41,
    )
    private val weekIds = intArrayOf(
        R.id.calendar_week_0, R.id.calendar_week_1, R.id.calendar_week_2,
        R.id.calendar_week_3, R.id.calendar_week_4, R.id.calendar_week_5,
    )

    private val weekEventIds = intArrayOf(
        R.id.calendar_week_events_0, R.id.calendar_week_events_1, R.id.calendar_week_events_2,
        R.id.calendar_week_events_3, R.id.calendar_week_events_4, R.id.calendar_week_events_5,
    )

    fun forget(widgetId: Int) {
        states.remove(widgetId)
        monthViews.remove(widgetId)
    }

    fun update(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        forceFull: Boolean = false,
    ) {
        val groupId = CalendarWidgetData.targetGroup(context)
        val cache = CalendarWidgetData.read(context)
        val appearance = WidgetAppearance.forWidget(manager, widgetId)
        val selected = CalendarWidgetData.selectedDate(context, widgetId)
        val loadState = CalendarWidgetData.loadState(context, selected)
        if (groupId.isEmpty() || cache == null) {
            val view = RemoteViews(context.packageName, appearance.calendarLayout)
            view.setViewVisibility(R.id.calendar_content, View.GONE)
            view.setViewVisibility(R.id.calendar_message, View.VISIBLE)
            view.setTextViewText(R.id.calendar_message, if (groupId.isEmpty()) {
                "表示対象グループを設定してください"
            } else {
                loadState.message
            })
            view.setOnClickPendingIntent(R.id.calendar_message, if (groupId.isEmpty()) {
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("memoraWidget://openSettings"),
                )
            } else if (loadState.canRetry) {
                calendarWidgetAction(context, widgetId)
            } else null)
            manager.updateAppWidget(widgetId, view)
            forget(widgetId)
            return
        }
        val month = selected.withDayOfMonth(1)
        val cachedMonth = CalendarWidgetData.readMonth(context, cache, month)
        val options = manager.getAppWidgetOptions(widgetId)
        val sizes = Sizes(
            Size(
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250),
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 280),
            ),
            Size(
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 250),
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 280),
            ),
        )
        val settings = CalendarWidgetDisplaySettings.read(context)
        val next = RenderedState(
            groupId, cachedMonth ?: CalendarWidgetData.emptyMonth(month, settings.weekStartsOnMonday), cachedMonth != null,
            loadState, sizes, LocalDate.now(), selected, cache.lastUpdatedAt, appearance, settings,
        )
        val previous = states[widgetId]
        val full = forceFull || previous == null || monthViews[widgetId] == null ||
            previous.copy(selected = selected, lastUpdatedAt = cache.lastUpdatedAt) != next
        if (!full && previous == next) return
        if (full) {
            val portrait = RemoteViews(context.packageName, appearance.calendarLayout)
            val landscape = RemoteViews(context.packageName, appearance.calendarLayout)
            renderMonth(context, portrait, widgetId, next, sizes.portrait)
            renderMonth(context, landscape, widgetId, next, sizes.landscape)
            monthViews[widgetId] = MonthViews(portrait, landscape)
        }
        val cached = requireNotNull(monthViews[widgetId])
        val portrait = copyViews(cached.portrait)
        val landscape = copyViews(cached.landscape)
        updateSelection(context, portrait, widgetId, next)
        updateSelection(context, landscape, widgetId, next)
        manager.updateAppWidget(widgetId, RemoteViews(landscape, portrait))
        states[widgetId] = next
        if (Build.VERSION.SDK_INT < 31) {
            manager.notifyAppWidgetViewDataChanged(widgetId, R.id.calendar_events)
        }
    }

    private fun renderMonth(
        context: Context,
        views: RemoteViews,
        widgetId: Int,
        state: RenderedState,
        size: Size,
    ) {
        val month = state.month.month
        val weekdayIds = intArrayOf(
            R.id.calendar_weekday_0, R.id.calendar_weekday_1, R.id.calendar_weekday_2,
            R.id.calendar_weekday_3, R.id.calendar_weekday_4, R.id.calendar_weekday_5, R.id.calendar_weekday_6,
        )
        state.settings.weekdays.forEachIndexed { index, name ->
            views.setTextViewText(weekdayIds[index], name)
            views.setTextColor(weekdayIds[index], when (name) {
                "日" -> state.appearance.sunday
                "土" -> state.appearance.saturday
                else -> state.appearance.text
            })
        }
        val compactHeader = size.width < 316
        val shortWidget = size.height < 324
        val headerHeight = if (shortWidget) 40 else 56
        val weekdaysHeight = if (shortWidget) 16 else 20
        val dayHeadingHeight = if (shortWidget) 24 else 28
        views.setInt(R.id.calendar_header, "setMinimumHeight", dp(context, headerHeight))
        views.setInt(R.id.calendar_weekdays, "setMinimumHeight", dp(context, weekdaysHeight))
        views.setInt(R.id.calendar_day_heading, "setMinimumHeight", dp(context, dayHeadingHeight))
        val gap = dp(context, if (compactHeader) 4 else 16)
        views.setViewVisibility(R.id.calendar_content, View.VISIBLE)
        views.setViewVisibility(R.id.calendar_message, View.GONE)
        views.setViewPadding(R.id.calendar_header_gap_start, gap, 0, 0, 0)
        views.setViewPadding(R.id.calendar_header_gap_end, gap, 0, 0, 0)
        val arrowPadding = dp(context, if (compactHeader) 0 else 8)
        views.setViewPadding(R.id.calendar_previous, arrowPadding, 0, arrowPadding, 0)
        views.setViewPadding(R.id.calendar_next, arrowPadding, 0, arrowPadding, 0)
        views.setTextViewTextSize(
            R.id.calendar_month, TypedValue.COMPLEX_UNIT_SP, if (compactHeader) 13f else 16f,
        )
        views.setTextViewText(R.id.calendar_month, "${month.year}年${month.monthValue}月")
        views.setOnClickPendingIntent(
            R.id.calendar_today, calendarWidgetAction(context, widgetId, today = true),
        )
        views.setOnClickPendingIntent(
            R.id.calendar_previous, calendarWidgetAction(context, widgetId, month.minusMonths(1)),
        )
        views.setOnClickPendingIntent(
            R.id.calendar_next, calendarWidgetAction(context, widgetId, month.plusMonths(1)),
        )
        views.setOnClickPendingIntent(R.id.calendar_refresh, calendarWidgetAction(context, widgetId))
        val rows = state.month.days.size / 7
        val reservedHeight = if (shortWidget) {
            headerHeight + weekdaysHeight + dayHeadingHeight + 16 + 40
        } else {
            180
        }
        val minimumRowHeight = if (shortWidget) 24f else 26f
        val rowHeight = ((size.height - reservedHeight.toFloat()) / rows)
            .coerceIn(minimumRowHeight, 64f)
        val compactDay = rowHeight < 58f
        val visibleEvents = when {
            rowHeight >= 40f -> 3
            rowHeight >= 32f -> 2
            else -> 1
        }
        weekIds.forEachIndexed { index, id ->
            views.setViewVisibility(id, if (index < rows) View.VISIBLE else View.GONE)
            views.setInt(id, "setMinimumHeight", dp(context, rowHeight))
        }
        state.month.days.forEachIndexed { index, day ->
            val cell = RemoteViews(context.packageName, if (compactDay) {
                R.layout.calendar_widget_day_compact
            } else {
                R.layout.calendar_widget_day
            })
            cell.setTextViewText(R.id.calendar_day_number, day.date.dayOfMonth.toString())
            cell.setTextColor(R.id.calendar_day_number, when {
                day.date.month != month.month -> state.appearance.mutedDate
                else -> day.dateColor(state.appearance)
            })
            cell.setTextViewText(R.id.calendar_day_rokuyo, day.rokuyo.orEmpty())
            cell.setTextColor(R.id.calendar_day_rokuyo, if (day.date.month != month.month) {
                state.appearance.mutedDate
            } else state.appearance.text)
            cell.setViewVisibility(R.id.calendar_day_rokuyo,
                if (state.settings.showRokuyo && !day.rokuyo.isNullOrEmpty()) View.VISIBLE else View.GONE)
            cell.setInt(R.id.calendar_day_number, "setPaintFlags", if (day.date == state.today) {
                android.graphics.Paint.FAKE_BOLD_TEXT_FLAG or android.graphics.Paint.ANTI_ALIAS_FLAG
            } else {
                android.graphics.Paint.ANTI_ALIAS_FLAG
            })
            cell.removeAllViews(R.id.calendar_day_events)
            val id = dayIds[index]
            views.removeAllViews(id)
            if (Build.VERSION.SDK_INT >= 31) {
                views.addStableView(id, cell, index)
            } else {
                views.addView(id, cell)
            }
            views.setOnClickPendingIntent(id, calendarWidgetAction(context, widgetId, day.date))
            setDaySelection(views, id, day, false, state.appearance)
        }
        state.month.days.chunked(7).forEachIndexed { week, days ->
            views.setImageViewBitmap(weekEventIds[week], CalendarWidgetWeekImage.render(
                context, days, month, (size.width - 16).coerceAtLeast(7), rowHeight,
                compactDay, visibleEvents, state.appearance,
            ))
        }
        if (Build.VERSION.SDK_INT < 31) {
            val adapter = Intent(context, CalendarWidgetListService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("memoraCalendar://list/$widgetId")
            }
            views.setRemoteAdapter(R.id.calendar_events, adapter)
        }
        views.setEmptyView(R.id.calendar_events, R.id.calendar_empty)
        views.setPendingIntentTemplate(
            R.id.calendar_events, widgetListLaunchIntent(context, widgetId),
        )
    }

    private fun updateSelection(
        context: Context,
        views: RemoteViews,
        widgetId: Int,
        state: RenderedState,
    ) {
        state.month.days.forEachIndexed { index, day ->
            if (day.date == state.selected) {
                setDaySelection(views, dayIds[index], day, true, state.appearance)
                views.setOnClickPendingIntent(dayIds[index], HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    calendarLaunchUri(state.groupId, day.date, create = true),
                ))
            }
        }
        val selectedDay = state.month.days.firstOrNull { it.date == state.selected }
        views.setTextViewText(R.id.calendar_selected_date,
            calendarWidgetDateLabel(state.selected.format(dateFormat), selectedDay, state.settings))
        views.setTextColor(R.id.calendar_selected_date,
            (selectedDay ?: CalendarWidgetDay(state.selected, emptyList())).dateColor(state.appearance))
        val lastUpdatedAt = state.lastUpdatedAt.replace("-", "/").replace("T", " ").take(16)
        views.setTextViewText(R.id.calendar_last_updated, "最終更新 $lastUpdatedAt")
        views.setViewVisibility(
            R.id.calendar_last_updated, if (lastUpdatedAt.isBlank()) View.GONE else View.VISIBLE,
        )
        views.setTextViewText(
            R.id.calendar_empty, if (state.loaded) "予定はありません" else state.loadState.message,
        )
        views.setOnClickPendingIntent(R.id.calendar_empty, if (state.loaded || !state.loadState.canRetry) null else {
            calendarWidgetAction(context, widgetId, state.selected)
        })
        if (Build.VERSION.SDK_INT >= 31) {
            val items = RemoteViews.RemoteCollectionItems.Builder()
                .setHasStableIds(false)
                .setViewTypeCount(1)
            val events = calendarWidgetEventsForDate(state.month, state.selected)
            events.forEachIndexed { index, event ->
                items.addItem(
                    index.toLong(),
                    calendarEventRow(context, state.groupId, state.selected, event, state.appearance),
                )
            }
            views.setRemoteAdapter(R.id.calendar_events, items.build())
        }
        val open = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, calendarLaunchUri(state.groupId, state.selected),
        )
        views.setOnClickPendingIntent(R.id.calendar_month, open)
        views.setOnClickPendingIntent(R.id.calendar_selected_date, open)
        views.setOnClickPendingIntent(R.id.calendar_add, HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java,
            calendarLaunchUri(state.groupId, state.selected, create = true),
        ))
        views.setScrollPosition(R.id.calendar_events, 0)
    }

    private fun setDaySelection(
        views: RemoteViews,
        id: Int,
        day: CalendarWidgetDay,
        selected: Boolean,
        appearance: WidgetAppearance,
    ) {
        views.setInt(id, "setBackgroundColor", if (selected) appearance.selected else appearance.background)
        views.setContentDescription(
            id, "${day.date.format(dateFormat)}、予定${day.events.size}件${if (selected) "、選択中" else ""}${day.displayEvents.joinToString(separator = "、", prefix = if (day.displayEvents.isEmpty()) "" else "、") { it.title }}",
        )
    }

    private fun dp(context: Context, value: Int): Int = dp(context, value.toFloat())
    private fun dp(context: Context, value: Float): Int =
        (value * context.resources.displayMetrics.density).roundToInt()

    @Suppress("DEPRECATION")
    private fun copyViews(views: RemoteViews): RemoteViews =
        if (Build.VERSION.SDK_INT >= 28) RemoteViews(views) else views.clone()
}

internal fun calendarLaunchUri(groupId: String, date: LocalDate, create: Boolean = false): Uri =
    Uri.Builder().scheme("memoraWidget").authority("openCalendar")
        .appendQueryParameter("groupId", groupId)
        .appendQueryParameter("date", date.toString())
        .appendQueryParameter("create", create.toString()).build()
