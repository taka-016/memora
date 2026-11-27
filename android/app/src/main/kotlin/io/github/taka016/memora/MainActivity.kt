package io.github.taka016.memora

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StandardMethodCodec

class MainActivity : FlutterActivity() {
    private val calendarLaunchInbox = CalendarLaunchInbox()
    private var calendarLaunchChannel: MethodChannel? = null
    private var deviceCalendar: DeviceCalendarMethodChannelHandler? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        calendarLaunchInbox.receive(intent)
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        calendarLaunchChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "memora/calendar_launch",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "takePending") {
                    val pending = calendarLaunchInbox.takePending()
                    if (pending != null) setIntent(Intent(this, MainActivity::class.java).setAction(Intent.ACTION_MAIN))
                    result.success(pending)
                } else {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PlacesMethodChannelHandler.CHANNEL,
        ).setMethodCallHandler(PlacesMethodChannelHandler(applicationContext))

        if (BuildConfig.RESOLVED_APP_MODE == "online") {
            val handler = DeviceCalendarMethodChannelHandler(this)
            deviceCalendar = handler
            val messenger = flutterEngine.dartExecutor.binaryMessenger
            MethodChannel(
                messenger,
                DeviceCalendarMethodChannelHandler.CHANNEL,
                StandardMethodCodec.INSTANCE,
                messenger.makeBackgroundTaskQueue(),
            ).setMethodCallHandler(handler)
            EventChannel(messenger, DeviceCalendarMethodChannelHandler.CHANGES_CHANNEL)
                .setStreamHandler(handler)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (calendarLaunchInbox.receive(intent)) {
            calendarLaunchChannel?.invokeMethod("launchChanged", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        deviceCalendar?.onPermissionResult(requestCode)
    }

    override fun onDestroy() {
        deviceCalendar?.dispose()
        super.onDestroy()
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_POST_NOTIFICATIONS,
            )
        }
    }

    companion object {
        private const val REQUEST_POST_NOTIFICATIONS = 1001
    }
}
