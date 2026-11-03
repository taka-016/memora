package com.example.memora

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate

private const val ITINERARY_ACTION = "com.example.memora.action.ITINERARY_WIDGET"

open class ItineraryWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        widgetIds.forEach { ItineraryWidgetRenderer.update(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, widgetId: Int, newOptions: Bundle,
    ) {
        ItineraryWidgetRenderer.update(context, manager, widgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ITINERARY_ACTION) {
            val widgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
            )
            val manager = AppWidgetManager.getInstance(context)
            val provider = manager.getAppWidgetInfo(widgetId)?.provider?.className
            if (provider != ItineraryWidgetReceiver::class.java.name &&
                provider != ItineraryDarkWidgetReceiver::class.java.name) return
            val action = intent.getStringExtra("operation") ?: return
            if (action == "refresh") {
                requestItineraryRefresh(context, manual = true)
                return
            }
            val cache = ItineraryWidgetData.read(context)
            if (cache == null) {
                requestItineraryRefresh(context, extendCache = true)
                return
            }
            val current = ItineraryWidgetData.selectedId(context, cache)
            val index = cache.dateIds.indexOf(current)
            val target = when (action) {
                "previous" -> if (index > 0) cache.dateIds[index - 1] else null
                "next" -> if (index >= 0) cache.dateIds.getOrNull(index + 1) else null
                "recent" -> {
                    val today = LocalDate.now()
                    cache.dateIds.firstOrNull { id ->
                        !LocalDate.parse(id.takeLast(10)).isBefore(today)
                    } ?: cache.dateIds.lastOrNull()
                }
                else -> null
            } ?: return
            ItineraryWidgetData.select(context, target)
            val widgetIds = listOf(
                ItineraryWidgetReceiver::class.java, ItineraryDarkWidgetReceiver::class.java,
            ).flatMap { receiver ->
                manager.getAppWidgetIds(android.content.ComponentName(context, receiver)).toList()
            }.toIntArray()
            onUpdate(context, manager, widgetIds)
            val targetIndex = cache.dateIds.indexOf(target)
            val cachedIds = cache.dates.map { it.id }.toSet()
            val missingNeighbor = listOfNotNull(
                cache.dateIds.getOrNull(targetIndex - 1), cache.dateIds.getOrNull(targetIndex + 1),
            ).any { it !in cachedIds }
            if (target !in cachedIds || (target != current && missingNeighbor)) {
                requestItineraryRefresh(context, extendCache = true)
            }
        } else if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE &&
            !intent.getBooleanExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, false)) {
            AndroidWidgetUpdateFallbackScheduler.schedule(context)
            AndroidWidgetUpdateFallbackScheduler.recoverIfOverdue(context)
            requestItineraryRefresh(context)
        }
    }
}

internal fun itineraryWidgetAction(context: Context, widgetId: Int, operation: String): PendingIntent {
    val intent = Intent(context, ItineraryWidgetReceiver::class.java).apply {
        component = AppWidgetManager.getInstance(context).getAppWidgetInfo(widgetId)?.provider
        action = ITINERARY_ACTION
        data = Uri.parse("memoraItinerary://action/$widgetId/$operation")
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        putExtra("operation", operation)
        addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
    }
    return PendingIntent.getBroadcast(
        context, widgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

private fun requestItineraryRefresh(
    context: Context,
    manual: Boolean = false,
    extendCache: Boolean = false,
) {
    val uri = Uri.Builder().scheme("memoraWidget")
        .authority(if (manual) "refresh" else "itineraryrefresh")
    if (extendCache) uri.appendQueryParameter("extend", "true")
    HomeWidgetBackgroundIntent.getBroadcast(
        context, uri.build(),
    ).send()
}
