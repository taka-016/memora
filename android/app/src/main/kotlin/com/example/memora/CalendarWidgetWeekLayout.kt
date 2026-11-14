package com.example.memora

import java.time.LocalDate

internal data class CalendarWidgetWeekEntry(
    val event: CalendarWidgetEvent,
    val startColumn: Int,
    val endColumn: Int,
    val lane: Int,
) {
    val filled: Boolean get() = event.isAllDay || event.isMultiDay
}

internal class CalendarWidgetWeekLayout(
    days: List<CalendarWidgetDay>,
    month: LocalDate,
    maxLines: Int,
) {
    private data class EventKey(val groupId: String?, val id: String, val occurrence: String?, val startMillis: Long)
    private fun key(event: CalendarWidgetEvent) = EventKey(event.groupId, event.id, event.occurrence, event.startMillis)

    val entries = mutableListOf<CalendarWidgetWeekEntry>()
    val remainingCounts: List<Int>

    init {
        val columns = days.map { day ->
            if (day.date.year == month.year && day.date.month == month.month) day.displayEvents else emptyList()
        }
        val occupied = List(maxLines) { BooleanArray(7) }
        val visibleCounts = IntArray(7)
        fun place(event: CalendarWidgetEvent, start: Int, end: Int) {
            val lane = occupied.indexOfFirst { row -> (start..end).none { row[it] } }
            if (lane < 0) return
            entries.add(CalendarWidgetWeekEntry(event, start, end, lane))
            for (column in start..end) {
                occupied[lane][column] = true
                visibleCounts[column]++
            }
        }

        columns.forEachIndexed { column, events ->
            events.firstOrNull { it.isHoliday }?.let { place(it, column, column) }
        }
        val bands = columns.flatten()
            .filter { !it.isHoliday && (it.isAllDay || it.isMultiDay) }
            .distinctBy { key(it) }
            .sortedWith(calendarWidgetEventOrder.thenBy { it.id })
        bands.forEach { event ->
            val eventKey = key(event)
            val dates = columns.indices.filter { column -> columns[column].any { key(it) == eventKey } }
            place(event, dates.first(), dates.last())
        }
        columns.forEachIndexed { column, events ->
            events.filter { !it.isHoliday && !it.isAllDay && !it.isMultiDay }
                .forEach { place(it, column, column) }
        }
        remainingCounts = columns.mapIndexed { column, events -> events.size - visibleCounts[column] }
    }
}
