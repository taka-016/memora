package com.example.memora

internal data class CalendarWidgetPreviewRow(
    val title: String,
    val color: Int? = null,
    val textColor: Int? = null,
    val isAllDay: Boolean = false,
)

internal object CalendarWidgetDayPreview {
    fun rows(events: List<CalendarWidgetEvent>, maxLines: Int): List<CalendarWidgetPreviewRow> {
        require(maxLines > 0)
        val visibleCount = if (events.size > maxLines) maxLines - 1 else events.size
        val result = events.take(visibleCount).map { event ->
            CalendarWidgetPreviewRow(event.title, event.color, event.textColor, event.isAllDay)
        }
        return if (events.size > visibleCount) {
            result + CalendarWidgetPreviewRow("他${events.size - visibleCount}件")
        } else result
    }
}
