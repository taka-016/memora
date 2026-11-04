package com.example.memora

import android.Manifest
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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
                    val reader = DeviceCalendarReader(activity)
                    result.success(if (call.method == "calendars") reader.calendars() else reader.events(
                        requireNotNull(call.argument<List<String>>("calendarIds")),
                        requireNotNull(call.argument<Number>("from")).toLong(),
                        requireNotNull(call.argument<Number>("to")).toLong(),
                    ))
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

    companion object {
        const val CHANNEL = "memora/device_calendar"
        const val CHANGES_CHANNEL = "memora/device_calendar_changes"
        private const val REQUEST_READ_CALENDAR = 1002
    }
}
