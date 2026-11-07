package com.example.memora

import android.content.Context
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.text.style.SubscriptSpan
import java.time.LocalDate
import org.json.JSONObject

internal data class CalendarWidgetDisplaySettings(
    val weekStartsOnMonday: Boolean = false,
    val showRokuyo: Boolean = false,
) {
    val weekdays: List<String> get() = if (weekStartsOnMonday) {
        listOf("月", "火", "水", "木", "金", "土", "日")
    } else {
        listOf("日", "月", "火", "水", "木", "金", "土")
    }

    companion object {
        fun read(context: Context): CalendarWidgetDisplaySettings = runCatching {
            val raw = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.calendar_display_settings", null)
                ?: return@runCatching CalendarWidgetDisplaySettings()
            val data = JSONObject(raw)
            CalendarWidgetDisplaySettings(
                weekStartsOnMonday = data.optString("weekStart") == "monday",
                showRokuyo = data.optBoolean("showRokuyo"),
            )
        }.getOrDefault(CalendarWidgetDisplaySettings())
    }
}

internal enum class CalendarWidgetDayKind { WEEKDAY, SATURDAY, SUNDAY }

internal val CalendarWidgetDay.kind: CalendarWidgetDayKind get() = when {
    holidayName != null || date.dayOfWeek.value == 7 -> CalendarWidgetDayKind.SUNDAY
    date.dayOfWeek.value == 6 -> CalendarWidgetDayKind.SATURDAY
    else -> CalendarWidgetDayKind.WEEKDAY
}

internal fun CalendarWidgetDay.dateColor(appearance: WidgetAppearance): Int = when (kind) {
    CalendarWidgetDayKind.SUNDAY -> appearance.sunday
    CalendarWidgetDayKind.SATURDAY -> appearance.saturday
    CalendarWidgetDayKind.WEEKDAY -> appearance.text
}

internal fun calendarWidgetMonthForDisplay(
    month: CalendarWidgetMonth,
    weekStartsOnMonday: Boolean,
): CalendarWidgetMonth {
    val first = month.month.withDayOfMonth(1)
    val offset = if (weekStartsOnMonday) first.dayOfWeek.value - 1 else first.dayOfWeek.value % 7
    val start = first.minusDays(offset.toLong())
    val count = ((offset + first.lengthOfMonth() + 6) / 7) * 7
    val byDate = month.days.associateBy { it.date }
    return month.copy(days = List(count) { index ->
        val date = start.plusDays(index.toLong())
        byDate[date] ?: CalendarWidgetDay(date, emptyList())
    })
}

internal fun calendarWidgetDateLabel(
    text: String,
    day: CalendarWidgetDay?,
    settings: CalendarWidgetDisplaySettings,
): CharSequence {
    val rokuyo = day?.rokuyo?.takeIf { settings.showRokuyo && it.isNotEmpty() } ?: return text
    return SpannableString("$text $rokuyo").apply {
        setSpan(RelativeSizeSpan(.6f), text.length + 1, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        setSpan(SubscriptSpan(), text.length + 1, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
}
