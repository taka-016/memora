package com.example.memora

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class DailyCalendarWidgetTest {
    private val date = LocalDate.of(2026, 11, 8)
    private fun event(id: String, allDay: Boolean, start: Long) = CalendarWidgetEvent(
        id, null, id, allDay, 0, 0, if (allDay) "終日" else "9:30–10:30", start,
    )

    @Test
    fun `共有月キャッシュから選択日だけを終日と開始時刻の順で表示する`() {
        val early = event("早い予定", false, 1)
        val late = event("遅い予定", false, 2)
        val allDay = event("終日の予定", true, 0)
        val month = CalendarWidgetMonth(date.withDayOfMonth(1), listOf(
            CalendarWidgetDay(date.minusDays(1), listOf(event("前日", true, 0))),
            CalendarWidgetDay(date, listOf(late, early, allDay)),
        ))
        assertEquals(listOf(allDay, early, late), dailyCalendarEvents(month, date))
        assertEquals(emptyList<CalendarWidgetEvent>(), dailyCalendarEvents(month, date.plusDays(1)))
        assertEquals(emptyList<CalendarWidgetEvent>(), dailyCalendarEvents(null, date))
    }
}
