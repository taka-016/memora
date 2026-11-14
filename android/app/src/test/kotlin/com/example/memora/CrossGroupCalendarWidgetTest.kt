package com.example.memora

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CrossGroupCalendarWidgetTest {
    @Test
    fun `同じ予定IDと個別回でもグループが異なれば別々の帯にする`() {
        val first = CalendarWidgetEvent("same", "2026-11-02", "家族", true, 0, 0, "終日", groupId = "family")
        val second = first.copy(groupId = "friends", title = "友人")
        val date = LocalDate.of(2026, 11, 2)
        val days = (0L..6L).map { CalendarWidgetDay(date.plusDays(it), if (it < 2) listOf(first, second) else emptyList()) }
        val layout = CalendarWidgetWeekLayout(days, date.withDayOfMonth(1), 3)
        assertEquals(listOf("family", "friends"), layout.entries.map { it.event.groupId })
        assertEquals(listOf(0, 0, 0, 0, 0, 0, 0), layout.remainingCounts)
    }

    @Test
    fun `予定は元グループを渡し端末予定と祝日は保存先を固定しない`() {
        val event = CalendarWidgetEvent("same", null, "予定", false, 0, 0, "10:00", groupId = "family")
        assertEquals("family", event.openGroupId)
        assertNull(event.copy(isExternal = true).openGroupId)
        assertNull(event.copy(isHoliday = true).openGroupId)
    }
}
