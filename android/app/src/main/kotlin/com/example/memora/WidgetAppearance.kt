package com.example.memora

import android.appwidget.AppWidgetManager
import android.graphics.Color

internal enum class WidgetAppearance {
    LIGHT, DARK;

    val calendarLayout: Int
        get() = if (this == DARK) R.layout.calendar_widget_dark else R.layout.calendar_widget
    val calendarEventLayout: Int
        get() = if (this == DARK) R.layout.calendar_widget_event_dark else R.layout.calendar_widget_event
    val itineraryLayout: Int
        get() = if (this == DARK) R.layout.itinerary_widget_dark else R.layout.itinerary_widget
    val itineraryItemLayout: Int
        get() = if (this == DARK) R.layout.itinerary_widget_item_dark else R.layout.itinerary_widget_item
    val background: Int
        get() = if (this == DARK) Color.rgb(30, 30, 30) else Color.WHITE
    val text: Int
        get() = if (this == DARK) Color.rgb(238, 238, 238) else Color.DKGRAY
    val mutedDate: Int
        get() = if (this == DARK) Color.rgb(117, 117, 117) else Color.LTGRAY
    val sunday: Int
        get() = if (this == DARK) Color.rgb(255, 138, 128) else Color.rgb(211, 47, 47)
    val saturday: Int
        get() = if (this == DARK) Color.rgb(130, 177, 255) else Color.rgb(25, 118, 210)
    val selected: Int
        get() = if (this == DARK) Color.rgb(38, 70, 94) else Color.rgb(227, 242, 253)

    companion object {
        fun forWidget(manager: AppWidgetManager, widgetId: Int): WidgetAppearance =
            when (manager.getAppWidgetInfo(widgetId)?.provider?.className) {
                CalendarDarkWidgetReceiver::class.java.name,
                ItineraryDarkWidgetReceiver::class.java.name -> DARK
                else -> LIGHT
            }
    }
}

class CalendarDarkWidgetReceiver : CalendarWidgetReceiver()
class ItineraryDarkWidgetReceiver : ItineraryWidgetReceiver()
