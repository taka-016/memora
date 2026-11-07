package com.example.memora

import android.content.Context
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File
import java.time.LocalDate
import org.json.JSONObject

internal data class CalendarWidgetEvent(
    val id: String,
    val occurrence: String?,
    val title: String,
    val isAllDay: Boolean,
    val color: Int,
    val textColor: Int,
    val timeLabel: String,
    val startMillis: Long = 0L,
    val isExternal: Boolean = false,
) {
    val openEventId: String? get() = id
}

internal val calendarWidgetEventOrder = compareByDescending<CalendarWidgetEvent> { it.isAllDay }
    .thenBy { it.startMillis }

internal data class CalendarWidgetDay(
    val date: LocalDate,
    val events: List<CalendarWidgetEvent>,
)

internal data class CalendarWidgetMonth(
    val month: LocalDate,
    val days: List<CalendarWidgetDay>,
)

internal data class CalendarWidgetCache(
    val groupId: String,
    val sourceMode: String,
    val months: Map<LocalDate, CalendarWidgetMonth>,
    val lastUpdatedAt: String,
    val deviceCalendarOwnerId: String? = null,
)

internal object CalendarWidgetData {
    private const val CACHE_KEY = "memora_widget_calendar_cache"
    private const val SELECTED_DATE_KEY = "memora_widget_calendar_selected_date"
    private const val TARGET_GROUP_KEY = "memora_widget_target_group_id"
    private var path: String? = null
    private var modifiedAt = -1L
    private var length = -1L
    private var cache: CalendarWidgetCache? = null

    fun targetGroup(context: Context): String =
        HomeWidgetPlugin.getData(context).getString(TARGET_GROUP_KEY, null).orEmpty()

    @Synchronized
    fun read(context: Context): CalendarWidgetCache? = runCatching {
        val prefs = HomeWidgetPlugin.getData(context)
        val cachePath = prefs.getString(CACHE_KEY, null) ?: return@runCatching null
        val file = File(cachePath)
        if (!file.exists()) return@runCatching null
        val currentModifiedAt = file.lastModified()
        val currentLength = file.length()
        if (path != cachePath || modifiedAt != currentModifiedAt || length != currentLength) {
            val root = JSONObject(file.readText(Charsets.UTF_8))
            val months = root.getJSONObject("months")
            val parsedMonths = mutableMapOf<LocalDate, CalendarWidgetMonth>()
            months.keys().forEach { key ->
                val month = months.getJSONObject(key)
                val days = month.getJSONArray("days")
                val parsedDays = (0 until days.length()).map { index ->
                    val day = days.getJSONObject(index)
                    val events = day.getJSONArray("events")
                    CalendarWidgetDay(
                        LocalDate.parse(day.getString("date")),
                        (0 until events.length()).map { eventIndex ->
                            val event = events.getJSONObject(eventIndex)
                            CalendarWidgetEvent(
                                id = event.getString("id"),
                                occurrence = event.optString("occurrence").takeIf { it.isNotBlank() },
                                title = event.getString("title"),
                                isAllDay = event.optBoolean("isAllDay"),
                                color = parseColor(event.optString("color")),
                                textColor = parseColor(event.optString("textColor")),
                                timeLabel = event.getString("timeLabel"),
                                startMillis = event.optLong("startMillis"),
                            )
                        },
                    )
                }
                val date = LocalDate.parse(key)
                parsedMonths[date] = CalendarWidgetMonth(date, parsedDays)
            }
            val loaded = CalendarWidgetCache(
                root.getString("groupId"), root.getString("sourceMode"), parsedMonths,
                root.optString("lastUpdatedAt"),
                deviceCalendarOwnerId = if (root.isNull("deviceCalendarOwnerId")) null else root.getString("deviceCalendarOwnerId"),
            )
            path = cachePath
            modifiedAt = currentModifiedAt
            length = currentLength
            cache = loaded
        }
        cache?.takeIf {
            it.groupId == targetGroup(context) && it.sourceMode == BuildConfig.RESOLVED_APP_MODE
        }
    }.getOrNull()

    fun readMonth(context: Context, cache: CalendarWidgetCache, month: LocalDate): CalendarWidgetMonth? {
        val stored = cache.months[month] ?: return null
        val shared = stored.copy(days = stored.days.map { day ->
            day.copy(events = day.events.sortedWith(calendarWidgetEventOrder))
        })
        return DeviceCalendarWidgetSource.read(context, cache, shared)
    }

    fun selectedDate(context: Context, widgetId: Int): LocalDate {
        val prefs = HomeWidgetPlugin.getData(context)
        val date = if (prefs.getString(groupKey(widgetId), null) == targetGroup(context)) {
            prefs.getString(dateKey(widgetId), null)
                ?: prefs.getString(SELECTED_DATE_KEY, null)
        } else {
            prefs.getString(SELECTED_DATE_KEY, null)
        }
        return runCatching { LocalDate.parse(date) }.getOrNull() ?: LocalDate.now()
    }

    fun selectDate(context: Context, widgetId: Int, date: LocalDate) {
        HomeWidgetPlugin.getData(context).edit()
            .putString(dateKey(widgetId), date.toString())
            .putString(groupKey(widgetId), targetGroup(context))
            .putString(SELECTED_DATE_KEY, date.toString())
            .apply()
    }

    fun forgetWidget(context: Context, widgetId: Int) {
        HomeWidgetPlugin.getData(context).edit()
            .remove(dateKey(widgetId)).remove(groupKey(widgetId)).apply()
    }

    fun emptyMonth(month: LocalDate): CalendarWidgetMonth {
        val offset = month.dayOfWeek.value % 7
        val start = month.minusDays(offset.toLong())
        val count = ((offset + month.lengthOfMonth() + 6) / 7) * 7
        return CalendarWidgetMonth(month, List(count) { index ->
            CalendarWidgetDay(start.plusDays(index.toLong()), emptyList())
        })
    }

    private fun dateKey(widgetId: Int) = "memora_calendar_date_$widgetId"
    private fun groupKey(widgetId: Int) = "memora_calendar_group_$widgetId"
    private fun parseColor(value: String): Int =
        runCatching { Color.parseColor(value) }.getOrDefault(Color.GRAY)
}

internal fun calendarWidgetEventsForDate(month: CalendarWidgetMonth?, date: LocalDate): List<CalendarWidgetEvent> =
    month?.days?.firstOrNull { it.date == date }?.events
        .orEmpty().sortedWith(calendarWidgetEventOrder)
