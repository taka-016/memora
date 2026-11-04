package com.example.memora

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StandardMethodCodec

class MainActivity : FlutterActivity() {
    private var deviceCalendar: DeviceCalendarMethodChannelHandler? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
