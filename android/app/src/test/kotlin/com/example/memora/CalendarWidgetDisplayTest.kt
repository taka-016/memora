package com.example.memora

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class CalendarWidgetDisplayTest {
    @Test
    fun `週の始まりを切り替えても月境界の予定と暦情報を保持する`() {
        val first = LocalDate.of(2026, 11, 1)
        val days = List(42) { index ->
            val date = first.minusDays(6).plusDays(index.toLong())
            CalendarWidgetDay(date, emptyList(),
                holidayName = if (date == first.plusDays(2)) "文化の日" else null,
                rokuyo = if (date == first.plusDays(7)) "先勝" else "大安")
        }
        val month = CalendarWidgetMonth(first, days)
        val sunday = calendarWidgetMonthForDisplay(month, false)
        val monday = calendarWidgetMonthForDisplay(month, true)
        assertEquals(first, sunday.days.first().date)
        assertEquals(LocalDate.of(2026, 12, 5), sunday.days.last().date)
        assertEquals(first.minusDays(6), monday.days.first().date)
        assertEquals(LocalDate.of(2026, 12, 6), monday.days.last().date)
        assertEquals(35, sunday.days.size)
        assertEquals(42, monday.days.size)
        assertEquals("文化の日", monday.days.first { it.date == first.plusDays(2) }.holidayName)
        assertEquals("先勝", sunday.days.first { it.date == first.plusDays(7) }.rokuyo)
        assertEquals(listOf("月", "火", "水", "木", "金", "土", "日"),
            CalendarWidgetDisplaySettings(weekStartsOnMonday = true).weekdays)
    }

    @Test
    fun `土曜の祝日も日曜と同じ分類になり通常の土曜は青の分類になる`() {
        assertEquals(CalendarWidgetDayKind.SUNDAY,
            CalendarWidgetDay(LocalDate.of(2026, 11, 3), emptyList(), holidayName = "文化の日").kind)
        assertEquals(CalendarWidgetDayKind.SUNDAY,
            CalendarWidgetDay(LocalDate.of(2026, 11, 7), emptyList(), holidayName = "祝日").kind)
        assertEquals(CalendarWidgetDayKind.SATURDAY,
            CalendarWidgetDay(LocalDate.of(2026, 11, 7), emptyList()).kind)
        assertEquals(CalendarWidgetDayKind.SUNDAY,
            CalendarWidgetDay(LocalDate.of(2026, 11, 8), emptyList()).kind)
        assertEquals(CalendarWidgetDayKind.WEEKDAY,
            CalendarWidgetDay(LocalDate.of(2026, 11, 2), emptyList()).kind)
    }
}
