package io.github.taka016.memora

import android.content.Intent
import android.provider.CalendarContract

class CalendarLaunchInbox {
    private var pending: Map<String, Any?>? = null

    fun receive(intent: Intent): Boolean {
        val uri = intent.data
        val calendarIntent = intent.selector ?: intent
        val action = when {
            calendarIntent.action == Intent.ACTION_MAIN &&
                calendarIntent.hasCategory(Intent.CATEGORY_APP_CALENDAR) -> "view"
            intent.action == Intent.ACTION_VIEW && uri?.scheme == "content" &&
                uri.authority == CalendarContract.AUTHORITY &&
                uri.pathSegments.size == 2 && uri.pathSegments.first() == "time" &&
                uri.lastPathSegment?.toLongOrNull()?.let { it in -62135596800000L..253402300799999L } == true -> "view"
            intent.action == Intent.ACTION_INSERT && (
                uri == CalendarContract.Events.CONTENT_URI ||
                    intent.type == "vnd.android.cursor.dir/event"
                ) -> "create"
            else -> return false
        }
        pending = mapOf(
            "action" to action,
            "begin" to if (action == "view") uri?.lastPathSegment?.toLongOrNull()
                else intent.optionalLong(CalendarContract.EXTRA_EVENT_BEGIN_TIME),
            "end" to intent.optionalLong(CalendarContract.EXTRA_EVENT_END_TIME),
            "allDay" to intent.getBooleanExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, false),
            "title" to intent.getStringExtra(CalendarContract.Events.TITLE),
            "description" to intent.getStringExtra(CalendarContract.Events.DESCRIPTION),
            "location" to intent.getStringExtra(CalendarContract.Events.EVENT_LOCATION),
        )
        return true
    }

    fun takePending(): Map<String, Any?>? = pending.also { pending = null }

    private fun Intent.optionalLong(key: String): Long? =
        if (hasExtra(key)) getLongExtra(key, 0) else null
}
