package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

internal object ItineraryWidgetRenderer {
    fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val cache = ItineraryWidgetData.read(context)
        val targetGroup = ItineraryWidgetData.targetGroup(context)
        val selected = cache?.let { ItineraryWidgetData.selectedId(context, it) }
        val date = cache?.dates?.firstOrNull { it.id == selected }
        val appearance = WidgetAppearance.forWidget(manager, widgetId)
        val views = RemoteViews(context.packageName, appearance.itineraryLayout)
        views.setOnClickPendingIntent(R.id.itinerary_refresh, itineraryWidgetAction(context, widgetId, "refresh"))
        val updated = cache?.lastUpdatedAt.orEmpty()
        views.setTextViewText(R.id.itinerary_last_updated, "最終更新 $updated")
        views.setViewVisibility(R.id.itinerary_last_updated, if (updated.isEmpty()) View.GONE else View.VISIBLE)
        if (cache == null || selected == null) {
            views.setViewVisibility(R.id.itinerary_content, View.GONE)
            views.setViewVisibility(R.id.itinerary_message, View.VISIBLE)
            views.setTextViewText(R.id.itinerary_message, when {
                targetGroup.isEmpty() -> "表示対象グループが未設定です"
                cache == null -> "タップして旅程を読み込む"
                else -> "表示できる旅程がありません"
            })
            views.setOnClickPendingIntent(R.id.itinerary_message, if (targetGroup.isEmpty()) {
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("memoraWidget://openSettings"),
                )
            } else {
                itineraryWidgetAction(context, widgetId, "refresh")
            })
            manager.updateAppWidget(widgetId, views)
            return
        }
        views.setViewVisibility(R.id.itinerary_content, View.VISIBLE)
        views.setViewVisibility(R.id.itinerary_message, View.GONE)
        views.setTextViewText(R.id.itinerary_trip_name, date?.tripName ?: "旅程を読み込み中…")
        views.setTextViewText(R.id.itinerary_trip_period, date?.tripPeriodLabel.orEmpty())
        views.setTextViewText(R.id.itinerary_date, date?.dateLabel.orEmpty())
        views.setTextViewText(R.id.itinerary_empty, if (date == null) "旅程を読み込み中…" else "旅程項目がありません")
        views.setOnClickPendingIntent(R.id.itinerary_previous, itineraryWidgetAction(context, widgetId, "previous"))
        views.setOnClickPendingIntent(R.id.itinerary_next, itineraryWidgetAction(context, widgetId, "next"))
        views.setOnClickPendingIntent(R.id.itinerary_recent, itineraryWidgetAction(context, widgetId, "recent"))
        views.setOnClickPendingIntent(R.id.itinerary_trip_header, date?.let {
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, itineraryTripUri(it.tripId))
        })
        views.setEmptyView(R.id.itinerary_items, R.id.itinerary_empty)
        views.setPendingIntentTemplate(R.id.itinerary_items, widgetListLaunchIntent(context, widgetId))
        if (Build.VERSION.SDK_INT >= 31) {
            val items = RemoteViews.RemoteCollectionItems.Builder().setHasStableIds(false).setViewTypeCount(1)
            date?.items?.forEachIndexed { index, item ->
                items.addItem(index.toLong(), itineraryItemRow(context, date.tripId, item, appearance))
            }
            views.setRemoteAdapter(R.id.itinerary_items, items.build())
        } else {
            val adapter = Intent(context, ItineraryWidgetListService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("memoraItinerary://list/$widgetId")
            }
            views.setRemoteAdapter(R.id.itinerary_items, adapter)
        }
        views.setScrollPosition(R.id.itinerary_items, 0)
        manager.updateAppWidget(widgetId, views)
        if (Build.VERSION.SDK_INT < 31) {
            manager.notifyAppWidgetViewDataChanged(widgetId, R.id.itinerary_items)
        }
    }
}

internal fun itineraryTripUri(tripId: String): Uri = Uri.Builder()
    .scheme("memoraWidget").authority("openTrip").appendQueryParameter("tripId", tripId).build()

internal fun itineraryItemRow(
    context: Context,
    tripId: String,
    item: ItineraryWidgetItem,
    appearance: WidgetAppearance,
): RemoteViews =
    RemoteViews(context.packageName, appearance.itineraryItemLayout).apply {
        val times = item.timeLabel.split(" - ", limit = 2)
        val hasEnd = times.size == 2
        setTextViewText(R.id.itinerary_item_start, times[0])
        setTextViewText(R.id.itinerary_item_end, times.getOrElse(1) { "" })
        setViewVisibility(R.id.itinerary_item_separator, if (hasEnd) View.VISIBLE else View.GONE)
        setViewVisibility(R.id.itinerary_item_end, if (hasEnd) View.VISIBLE else View.GONE)
        setTextViewText(R.id.itinerary_item_name, item.name)
        setOnClickFillInIntent(R.id.itinerary_item_row, Intent().apply { data = itineraryTripUri(tripId) })
    }
