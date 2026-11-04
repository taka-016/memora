package com.example.memora

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class DeviceCalendarMethodChannelHandler(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var permissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            eventSink?.success(null)
        }
    }

    private fun hasReadPermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.READ_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "hasReadPermission" -> result.success(hasReadPermission())
                "requestReadPermission" -> activity.runOnUiThread {
                    if (hasReadPermission()) {
                        result.success(true)
                    } else if (permissionResult != null) {
                        result.error("calendar_unavailable", "カレンダーの権限確認中です", null)
                    } else {
                        permissionResult = result
                        activity.requestPermissions(
                            arrayOf(Manifest.permission.READ_CALENDAR),
                            REQUEST_READ_CALENDAR,
                        )
                    }
                }
                "calendars", "events" -> {
                    if (!hasReadPermission()) throw SecurityException()
                    result.success(if (call.method == "calendars") calendars() else events(call))
                }
                else -> result.notImplemented()
            }
        } catch (_: SecurityException) {
            result.error("calendar_permission_denied", "カレンダーの読み取り許可が必要です", null)
        } catch (_: Exception) {
            result.error("calendar_unavailable", "端末のカレンダーを取得できませんでした", null)
        }
    }

    fun onPermissionResult(requestCode: Int) {
        if (requestCode != REQUEST_READ_CALENDAR) return
        permissionResult?.success(hasReadPermission())
        permissionResult = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        if (!hasReadPermission()) {
            events.error("calendar_permission_denied", "カレンダーの読み取り許可が必要です", null)
            return
        }
        eventSink = events
        activity.contentResolver.registerContentObserver(
            Uri.parse("content://${CalendarContract.AUTHORITY}"),
            true,
            observer,
        )
    }

    override fun onCancel(arguments: Any?) {
        activity.contentResolver.unregisterContentObserver(observer)
        eventSink = null
    }

    fun dispose() {
        onCancel(null)
        permissionResult?.error("calendar_unavailable", "権限の確認を終了しました", null)
        permissionResult = null
    }

    private fun calendars(): List<Map<String, Any?>> {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
        )
        val result = mutableListOf<Map<String, Any?>>()
        val cursor = activity.contentResolver.query(
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

    private fun events(call: MethodCall): List<Map<String, Any?>> {
        val ids = requireNotNull(call.argument<List<String>>("calendarIds"))
        if (ids.isEmpty()) return emptyList()
        require(ids.all { it.toLongOrNull() != null })
        val from = requireNotNull(call.argument<Number>("from")).toLong()
        val to = requireNotNull(call.argument<Number>("to")).toLong()
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
        val cursor = activity.contentResolver.query(
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
        val cursor = activity.contentResolver.query(
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
        const val CHANNEL = "memora/device_calendar"
        const val CHANGES_CHANNEL = "memora/device_calendar_changes"
        private const val REQUEST_READ_CALENDAR = 1002
        private val RECURRENCE_COLUMNS = arrayOf(
            CalendarContract.Events.RRULE,
            CalendarContract.Events.RDATE,
            CalendarContract.Events.EXRULE,
            CalendarContract.Events.EXDATE,
        )
    }
}
