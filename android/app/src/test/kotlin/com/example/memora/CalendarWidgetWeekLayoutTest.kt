package com.example.memora

import java.time.LocalDate
import org.junit.Assert.*
import org.junit.Test

class CalendarWidgetWeekLayoutTest {
    private val month = LocalDate.of(2026, 11, 1)
    private fun event(id: String, allDay: Boolean = true, multiDay: Boolean = false,
                      occurrence: String = id, start: Long = 1L) = CalendarWidgetEvent(
        id = id, occurrence = occurrence, title = id, isAllDay = allDay,
        color = 1, textColor = 2, timeLabel = if (allDay) "終日" else "09:00–10:00",
        startMillis = start, isMultiDay = multiDay,
    )
    private fun week(start: LocalDate = month, events: Map<Int, List<CalendarWidgetEvent>> = emptyMap()) =
        List(7) { index -> CalendarWidgetDay(start.plusDays(index.toLong()), events[index].orEmpty()) }

    @Test
    fun `複数日に同じ回が含まれても週ごとに1本の帯を配置する`() {
        val trip = event("旅行", multiDay = true)
        val first = CalendarWidgetWeekLayout(week(events = (4..6).associateWith { listOf(trip) }), month, 3)
        val next = CalendarWidgetWeekLayout(week(month.plusDays(7), (0..2).associateWith { listOf(trip) }), month, 3)
        assertEquals(1, first.entries.size)
        assertEquals(4, first.entries.single().startColumn)
        assertEquals(6, first.entries.single().endColumn)
        assertEquals(0, next.entries.single().startColumn)
        assertEquals(2, next.entries.single().endColumn)
        assertTrue(first.entries.single().filled)
        assertTrue((first.remainingCounts + next.remainingCounts).all { it == 0 })
    }

    @Test
    fun `祝日を先頭にして重複する帯と単日時間指定を別段へ配置する`() {
        val band = event("旅行", multiDay = true)
        val timed = event("通院", allDay = false)
        val days = week(events = mapOf(1 to listOf(band), 2 to listOf(band, timed)))
            .mapIndexed { index, day -> if (index == 2) day.copy(holidayName = "文化の日") else day }
        val layout = CalendarWidgetWeekLayout(days, month, 3)
        assertEquals(listOf("文化の日", "旅行", "通院"), layout.entries.map { it.event.title })
        assertEquals(listOf(0, 1, 2), layout.entries.map { it.lane })
        assertEquals(1, layout.entries[1].startColumn)
        assertEquals(2, layout.entries[1].endColumn)
        assertTrue(layout.remainingCounts.all { it == 0 })
    }

    @Test
    fun `1段しかない場合は祝日を残し表示できない予定を日別に数える`() {
        val band = event("旅行", multiDay = true)
        val days = week(events = mapOf(1 to listOf(band), 2 to listOf(band)))
            .mapIndexed { index, day -> if (index == 2) day.copy(holidayName = "文化の日") else day }
        val layout = CalendarWidgetWeekLayout(days, month, 1)
        assertEquals("文化の日", layout.entries.single().event.title)
        assertEquals(listOf(0, 1, 1, 0, 0, 0, 0), layout.remainingCounts)
        assertEquals(listOf("文化の日", "旅行"), days[2].displayEvents.map { it.title })
        assertEquals("", days[2].displayEvents.first().timeLabel)
        assertNull(days[2].displayEvents.first().openEventId)
    }

    @Test
    fun `同じ系列の別の回をつなげず時刻付き複数日だけを帯にする`() {
        val first = event("毎日", occurrence = "1", start = 1)
        val second = event("毎日", occurrence = "2", start = 2)
        val long = event("夜行", allDay = false, multiDay = true, start = 3)
        val single = event("午前0時終了", allDay = false, start = 4)
        val layout = CalendarWidgetWeekLayout(week(events = mapOf(
            0 to listOf(first), 1 to listOf(second), 2 to listOf(long, single), 3 to listOf(long),
        )), month, 3)
        val repeated = layout.entries.filter { it.event.id == "毎日" }
        assertEquals(2, repeated.size)
        assertTrue(repeated.all { it.startColumn == it.endColumn })
        assertTrue(layout.entries.single { it.event.id == "夜行" }.filled)
        assertEquals(3, layout.entries.single { it.event.id == "夜行" }.endColumn)
        assertFalse(layout.entries.single { it.event.id == "午前0時終了" }.filled)
    }

    @Test
    fun `月境界では対象月の範囲に帯を切り出す`() {
        val oct = LocalDate.of(2026, 10, 1)
        val trip = event("月またぎ", multiDay = true)
        val layout = CalendarWidgetWeekLayout(
            week(LocalDate.of(2026, 9, 27), (3..6).associateWith { listOf(trip) }), oct, 3,
        )
        assertEquals(4, layout.entries.single().startColumn)
        assertEquals(6, layout.entries.single().endColumn)
        assertTrue(layout.remainingCounts.all { it == 0 })
    }
}
