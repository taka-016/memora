package com.example.memora

import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import org.junit.Assert.*
import org.junit.Test

class DeviceCalendarWidgetOverlayTest {
    private val zone = ZoneId.of("Asia/Tokyo")
    private val month = CalendarWidgetData.emptyMonth(LocalDate.of(2026, 11, 1))
    private fun millis(day: Int, hour: Int, utc: Boolean = false) =
        ZonedDateTime.of(2026, 11, day, hour, 0, 0, 0, if (utc) ZoneId.of("UTC") else zone)
            .toInstant().toEpochMilli()
    private fun event(id: String, begin: Long, end: Long, allDay: Boolean = false, calendar: String = "1") = mapOf<String, Any?>(
        "id" to id, "calendarId" to calendar, "begin" to begin, "end" to end,
        "allDay" to allDay, "title" to id,
    )

    @Test
    fun `終日予定はUTCの終了日を含めず午前0時終了の予定も翌日へ出さない`() {
        val result = DeviceCalendarWidgetOverlay.merge(month, listOf(
            event("旅行", millis(2, 0, true), millis(5, 0, true), true),
            event("夜", millis(2, 23), millis(3, 0)),
        ), mapOf("1" to "個人"), zone)
        fun titles(day: Int) = result.days.first { it.date.dayOfMonth == day && it.date.monthValue == 11 }.events.map { it.title }
        assertEquals(listOf("旅行 · 個人", "夜 · 個人"), titles(2))
        assertEquals(listOf("旅行 · 個人"), titles(3))
        assertEquals(listOf("旅行 · 個人"), titles(4))
        assertTrue(titles(5).isEmpty())
    }

    @Test
    fun `共有予定と端末予定を時刻順に重ねて元キャッシュは変更しない`() {
        val shared = CalendarWidgetEvent("shared", null, "家族の予定", false, 0, 0, "10:00–11:00", startMillis = millis(2, 10))
        val base = month.copy(days = month.days.map { if (it.date == LocalDate.of(2026, 11, 2)) it.copy(events = listOf(shared)) else it })
        val result = DeviceCalendarWidgetOverlay.merge(base, listOf(event("通院", millis(2, 9), millis(2, 10))), mapOf("1" to "個人"), zone)
        val items = result.days.first { it.date == LocalDate.of(2026, 11, 2) }.events
        assertEquals(listOf("通院 · 個人", "家族の予定"), items.map { it.title })
        assertTrue(items.first().isExternal)
        assertNull(items.first().openEventId)
        assertEquals("shared", items.last().openEventId)
        assertEquals(listOf(shared), base.days.first { it.date == LocalDate.of(2026, 11, 2) }.events)
    }

    @Test
    fun `未選択のカレンダーを含めず繰り返しの各回も異なる識別子で表示する`() {
        val rows = listOf(
            event("series:1", millis(2, 9), millis(2, 10)),
            event("series:2", millis(9, 9), millis(9, 10)),
            event("非表示", millis(2, 9), millis(2, 10), calendar = "2"),
        )
        val result = DeviceCalendarWidgetOverlay.merge(month, rows, mapOf("1" to "個人"), zone)
        val items = result.days.flatMap { it.events }
        assertEquals(2, items.size)
        assertEquals(2, items.map { it.id }.toSet().size)
        assertEquals(month, DeviceCalendarWidgetOverlay.merge(month, rows, emptyMap(), zone))
    }
}
