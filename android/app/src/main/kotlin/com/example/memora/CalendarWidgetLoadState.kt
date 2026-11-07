package com.example.memora

import java.time.LocalDate

internal enum class CalendarWidgetLoadState(val message: String, val canRetry: Boolean) {
    IDLE("タップして予定を読み込む", true),
    LOADING("読み込み中…", false),
    FAILED("読み込めませんでした。タップして再試行", true);

    companion object {
        fun fromValue(value: String?): CalendarWidgetLoadState = when {
            value == "loading" || value?.startsWith("loading:") == true -> LOADING
            value == "failed" -> FAILED
            else -> IDLE
        }
    }
}

internal fun calendarWidgetLoadStateKey(groupId: String, date: LocalDate): String =
    "memora_widget_calendar_load_${groupId}_${date.withDayOfMonth(1)}"

internal fun itineraryWidgetLoadStateKey(groupId: String, selectedId: String?): String =
    "memora_widget_itinerary_load_${groupId}_${selectedId ?: "recent"}"
