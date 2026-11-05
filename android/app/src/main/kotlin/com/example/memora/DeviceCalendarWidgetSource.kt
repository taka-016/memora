package com.example.memora

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import java.time.ZoneId
import org.json.JSONArray

internal object DeviceCalendarWidgetSource {
    fun read(context: Context, cache: CalendarWidgetCache, month: CalendarWidgetMonth): CalendarWidgetMonth {
        if (BuildConfig.RESOLVED_APP_MODE != "online" || cache.sourceMode != "online" ||
            cache.deviceCalendarOwnerId.isNullOrBlank() ||
            context.checkSelfPermission(Manifest.permission.READ_CALENDAR) != PackageManager.PERMISSION_GRANTED
        ) return month
        return runCatching {
            val raw = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.device_calendar_${Uri.encode(cache.deviceCalendarOwnerId)}", null)
                ?: return@runCatching month
            val connections = JSONArray(raw)
            val selected = mutableMapOf<String, Set<String>>()
            for (index in 0 until connections.length()) {
                val connection = connections.getJSONObject(index)
                val ids = connection.getJSONArray("calendarIds")
                selected[connection.getString("accountId")] = (0 until ids.length()).map { ids.getString(it) }.toSet()
            }
            if (selected.values.all { it.isEmpty() }) return@runCatching month
            val reader = DeviceCalendarReader(context)
            val names = reader.calendars().filter { calendar ->
                selected[calendar["accountId"] as String]?.contains(calendar["id"] as String) == true
            }.associate { it["id"] as String to it["name"] as String }
            if (names.isEmpty()) return@runCatching month
            val zone = ZoneId.systemDefault()
            val from = month.days.first().date.atStartOfDay(zone).toInstant().toEpochMilli()
            val to = month.days.last().date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
            DeviceCalendarWidgetOverlay.merge(month, reader.events(names.keys.toList(), from, to), names, zone)
        }.getOrDefault(month)
    }
}
