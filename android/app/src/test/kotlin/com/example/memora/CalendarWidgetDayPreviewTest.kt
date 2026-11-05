package com.example.memora

import org.junit.Assert.*
import org.junit.Test

class CalendarWidgetDayPreviewTest {
    private fun events(count: Int) = (1..count).map { index ->
        CalendarWidgetEvent("$index", null, "予定$index", index % 2 == 0, index, index + 10, "終日")
    }

    @Test
    fun `3件まではすべての予定を順序と色を保って表示する`() {
        for (count in 0..3) {
            val source = events(count)
            val rows = CalendarWidgetDayPreview.rows(source, 3)
            assertEquals(source.map { it.title }, rows.map { it.title })
            assertTrue(rows.all { it.remainingCount == 0 })
            assertEquals(source.map { it.color }, rows.map { it.color })
            assertEquals(source.map { it.isAllDay }, rows.map { it.isAllDay })
            assertEquals(source.map { it.textColor }, rows.map { it.textColor })
        }
    }

    @Test
    fun `4件以上も先頭3件を表示し最終行に残件数を添える`() {
        for (count in listOf(4, 5, 8)) {
            val source = events(count)
            val rows = CalendarWidgetDayPreview.rows(source, 3)
            assertEquals(listOf("予定1", "予定2", "予定3"), rows.map { it.title })
            assertEquals(listOf(0, 0, count - 3), rows.map { it.remainingCount })
            assertEquals(source.last { it.title == "予定3" }.color, rows.last().color)
            assertEquals(count, source.size)
        }
    }

    @Test
    fun `小さいマスでは収まる行数の最終行に残件数を表示する`() {
        assertEquals(listOf("予定1", "予定2"), CalendarWidgetDayPreview.rows(events(4), 2).map { it.title })
        assertEquals(listOf(0, 2), CalendarWidgetDayPreview.rows(events(4), 2).map { it.remainingCount })
        assertEquals("予定1", CalendarWidgetDayPreview.rows(events(4), 1).single().title)
        assertEquals(3, CalendarWidgetDayPreview.rows(events(4), 1).single().remainingCount)
    }
}
