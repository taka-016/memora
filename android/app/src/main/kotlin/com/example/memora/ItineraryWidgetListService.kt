package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class ItineraryWidgetListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = object : RemoteViewsFactory {
        private val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        private var date: ItineraryWidgetDate? = null
        override fun onCreate() {
            onDataSetChanged()
        }
        override fun onDataSetChanged() {
            val cache = ItineraryWidgetData.read(applicationContext)
            val selected = cache?.let { ItineraryWidgetData.selectedId(applicationContext, it) }
            date = cache?.dates?.firstOrNull { it.id == selected }
        }
        override fun getViewAt(position: Int): RemoteViews? {
            val current = date ?: return null
            val item = current.items.getOrNull(position) ?: return null
            return itineraryItemRow(
                applicationContext, current.tripId, item,
                WidgetAppearance.forWidget(AppWidgetManager.getInstance(applicationContext), widgetId),
            )
        }
        override fun getCount(): Int = date?.items?.size ?: 0
        override fun getItemId(position: Int): Long = position.toLong()
        override fun hasStableIds(): Boolean = false
        override fun getViewTypeCount(): Int = 1
        override fun getLoadingView(): RemoteViews? = null
        override fun onDestroy() {
            date = null
        }
    }
}
