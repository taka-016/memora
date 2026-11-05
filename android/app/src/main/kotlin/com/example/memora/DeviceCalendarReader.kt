package com.example.memora

import android.content.Context
import android.content.ContentUris
import android.database.Cursor
import android.provider.CalendarContract
import org.json.JSONArray

internal class DeviceCalendarReader(private val context: Context) {
    fun calendars(): List<Map<String, Any?>> {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
        )
        val result = mutableListOf<Map<String, Any?>>()
        val cursor = context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ?",
            arrayOf(CalendarContract.Calendars.CAL_ACCESS_READ.toString()),
            "${CalendarContract.Calendars.ACCOUNT_NAME} ASC, ${CalendarContract.Calendars._ID} ASC",
        ) ?: throw IllegalStateException()
        cursor.use {
            while (it.moveToNext()) {
                val name = it.string(CalendarContract.Calendars.ACCOUNT_NAME) ?: "この端末"
                val type = it.string(CalendarContract.Calendars.ACCOUNT_TYPE).orEmpty()
                result.add(mapOf(
                    "id" to it.number(CalendarContract.Calendars._ID).toString(),
                    "name" to (it.string(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME) ?: "名称未設定"),
                    "accountId" to JSONArray(listOf(type, name)).toString(),
                    "accountName" to name,
                ))
            }
        }
        return result
    }

    fun events(ids: List<String>, from: Long, to: Long): List<Map<String, Any?>> {
        if (ids.isEmpty()) return emptyList()
        require(ids.all { it.toLongOrNull() != null })
        require(from < to)
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().apply {
            ContentUris.appendId(this, from)
            ContentUris.appendId(this, to)
        }.build()
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.ALL_DAY,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Events.EVENT_LOCATION,
            CalendarContract.Events.EVENT_TIMEZONE,
            CalendarContract.Events.ORIGINAL_ID,
            *RECURRENCE_COLUMNS,
        )
        val selection = "${CalendarContract.Instances.CALENDAR_ID} IN (${ids.joinToString(",") { "?" }})" +
            " AND (${CalendarContract.Events.STATUS} IS NULL OR ${CalendarContract.Events.STATUS} != ?)"
        val cursor = context.contentResolver.query(
            uri,
            projection,
            selection,
            (ids + CalendarContract.Events.STATUS_CANCELED.toString()).toTypedArray(),
            "${CalendarContract.Instances.BEGIN} ASC",
        ) ?: throw IllegalStateException()
        val result = mutableListOf<Map<String, Any?>>()
        val parentRules = mutableMapOf<Long, List<String>>()
        cursor.use {
            while (it.moveToNext()) {
                val eventId = it.number(CalendarContract.Instances.EVENT_ID)
                val begin = it.number(CalendarContract.Instances.BEGIN)
                val parentId = it.number(CalendarContract.Events.ORIGINAL_ID)
                val ownRules = recurrence(it)
                val rules = if (ownRules.isEmpty() && parentId > 0) {
                    parentRules.getOrPut(parentId) { recurrenceForEvent(parentId) }
                } else ownRules
                result.add(mapOf(
                    "id" to "$eventId:$begin",
                    "calendarId" to it.number(CalendarContract.Instances.CALENDAR_ID).toString(),
                    "begin" to begin,
                    "end" to it.number(CalendarContract.Instances.END),
                    "title" to it.string(CalendarContract.Events.TITLE),
                    "allDay" to (it.number(CalendarContract.Events.ALL_DAY) == 1L),
                    "description" to it.string(CalendarContract.Events.DESCRIPTION),
                    "location" to it.string(CalendarContract.Events.EVENT_LOCATION),
                    "timeZone" to it.string(CalendarContract.Events.EVENT_TIMEZONE),
                    "recurrence" to rules,
                    "isRecurring" to (rules.isNotEmpty() || parentId > 0),
                ))
            }
        }
        return result
    }

    private fun recurrenceForEvent(eventId: Long): List<String> {
        val cursor = context.contentResolver.query(
            ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId),
            RECURRENCE_COLUMNS, null, null, null,
        ) ?: throw IllegalStateException()
        return cursor.use { if (it.moveToFirst()) recurrence(it) else emptyList() }
    }

    private fun recurrence(cursor: Cursor): List<String> = RECURRENCE_COLUMNS.mapNotNull { column ->
        cursor.string(column)?.takeIf { it.isNotBlank() }?.let { "${column.uppercase()}:$it" }
    }

    private fun Cursor.string(column: String): String? = getString(getColumnIndexOrThrow(column))
    private fun Cursor.number(column: String): Long = getLong(getColumnIndexOrThrow(column))

    companion object {
        private val RECURRENCE_COLUMNS = arrayOf(
            CalendarContract.Events.RRULE,
            CalendarContract.Events.RDATE,
            CalendarContract.Events.EXRULE,
            CalendarContract.Events.EXDATE,
        )
    }
}
