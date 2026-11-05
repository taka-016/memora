package com.example.memora

import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

internal object DeviceCalendarWidgetOverlay {
    private data class Occurrence(val begin: Long, val end: Long, val event: CalendarWidgetEvent)

    fun merge(
        month: CalendarWidgetMonth,
        rows: List<Map<String, Any?>>,
        calendarNames: Map<String, String>,
        zone: ZoneId,
    ): CalendarWidgetMonth {
        if (calendarNames.isEmpty()) return month
        val timeFormat = DateTimeFormatter.ofPattern("HH:mm").withZone(zone)
        val occurrences = rows.mapNotNull { row ->
            val calendarId = row["calendarId"] as String
            if (calendarId !in calendarNames) return@mapNotNull null
            val begin = (row["begin"] as Number).toLong()
            val end = (row["end"] as Number).toLong()
            val allDay = row["allDay"] as Boolean
            Occurrence(begin, end, CalendarWidgetEvent(
                id = "device:$calendarId:${row["id"]}",
                occurrence = null,
                title = (row["title"] as? String)?.takeIf { it.isNotBlank() } ?: "予定あり",
                isAllDay = allDay,
                color = 0xFF1967D2.toInt(),
                textColor = 0xFFFFFFFF.toInt(),
                timeLabel = if (allDay) "終日" else "${timeFormat.format(Instant.ofEpochMilli(begin))}–${timeFormat.format(Instant.ofEpochMilli(end))}",
                startMillis = begin,
                isExternal = true,
            ))
        }
        if (occurrences.isEmpty()) return month
        return month.copy(days = month.days.map { day ->
            val start = day.date.atStartOfDay(zone).toInstant().toEpochMilli()
            val end = day.date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
            val external = occurrences.filter { occurrence ->
                if (occurrence.event.isAllDay) {
                    val first = Instant.ofEpochMilli(occurrence.begin).atZone(ZoneOffset.UTC).toLocalDate()
                    val last = Instant.ofEpochMilli(occurrence.end).atZone(ZoneOffset.UTC).toLocalDate()
                    !day.date.isBefore(first) && day.date.isBefore(last)
                } else {
                    occurrence.begin < end && (occurrence.end > start ||
                        (occurrence.begin == occurrence.end && occurrence.begin >= start))
                }
            }.map { it.event }
            day.copy(events = (day.events + external).sortedWith(calendarWidgetEventOrder))
        })
    }
}
