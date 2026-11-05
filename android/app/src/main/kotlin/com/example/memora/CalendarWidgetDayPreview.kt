package com.example.memora

internal data class CalendarWidgetPreviewRow(
    val title: String,
    val color: Int,
    val textColor: Int,
    val isAllDay: Boolean,
    val remainingCount: Int = 0,
)

internal object CalendarWidgetDayPreview {
    fun rows(events: List<CalendarWidgetEvent>, maxLines: Int): List<CalendarWidgetPreviewRow> {
        require(maxLines > 0)
        val visible = events.take(maxLines)
        return visible.mapIndexed { index, event ->
            CalendarWidgetPreviewRow(
                event.title, event.color, event.textColor, event.isAllDay,
                if (index == visible.lastIndex) events.size - visible.size else 0,
            )
        }
    }
}
