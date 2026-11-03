package com.example.memora

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File
import org.json.JSONObject

internal data class ItineraryWidgetItem(val name: String, val timeLabel: String)
internal data class ItineraryWidgetDate(
    val id: String,
    val tripId: String,
    val tripName: String,
    val tripPeriodLabel: String,
    val dateLabel: String,
    val items: List<ItineraryWidgetItem>,
)
internal data class ItineraryWidgetCache(
    val groupId: String,
    val selectedId: String?,
    val recentId: String?,
    val dateIds: List<String>,
    val dates: List<ItineraryWidgetDate>,
    val lastUpdatedAt: String,
)

internal object ItineraryWidgetData {
    private const val CACHE_KEY = "memora_widget_itinerary_cache"
    private const val SELECTED_KEY = "memora_widget_selected_itinerary_date_id"
    private var path: String? = null
    private var modifiedAt = -1L
    private var length = -1L
    private var cache: ItineraryWidgetCache? = null

    fun targetGroup(context: Context): String = HomeWidgetPlugin.getData(context)
        .getString("memora_widget_target_group_id", null).orEmpty()

    @Synchronized
    fun read(context: Context): ItineraryWidgetCache? = runCatching {
        val prefs = HomeWidgetPlugin.getData(context)
        val cachePath = prefs.getString(CACHE_KEY, null) ?: return@runCatching null
        val file = File(cachePath)
        if (!file.exists()) return@runCatching null
        if (path != cachePath || modifiedAt != file.lastModified() || length != file.length()) {
            val root = JSONObject(file.readText(Charsets.UTF_8))
            if (root.getString("sourceMode") != BuildConfig.RESOLVED_APP_MODE) {
                return@runCatching null
            }
            val ids = root.getJSONArray("itineraryDateIds")
            val dates = root.getJSONArray("itineraryDates")
            val loaded = ItineraryWidgetCache(
                groupId = root.getString("groupId"),
                selectedId = root.optString("selectedItineraryDateId").takeUnless { it.isBlank() || it == "null" },
                recentId = root.optString("recentItineraryDateId").takeUnless { it.isBlank() || it == "null" },
                dateIds = List(ids.length()) { ids.getString(it) },
                dates = List(dates.length()) { index ->
                    val date = dates.getJSONObject(index)
                    val items = date.getJSONArray("itineraryItems")
                    ItineraryWidgetDate(
                        id = date.getString("id"), tripId = date.getString("tripId"),
                        tripName = date.getString("tripName"),
                        tripPeriodLabel = date.getString("tripPeriodLabel"),
                        dateLabel = date.getString("dateLabel"),
                        items = List(items.length()) { itemIndex ->
                            val item = items.getJSONObject(itemIndex)
                            ItineraryWidgetItem(item.getString("name"), item.getString("timeLabel"))
                        },
                    )
                },
                lastUpdatedAt = root.optString("lastUpdatedAt").replace("-", "/")
                    .replace("T", " ").take(16),
            )
            path = cachePath
            modifiedAt = file.lastModified()
            length = file.length()
            cache = loaded
        }
        cache?.takeIf { it.groupId == targetGroup(context) }
    }.getOrNull()

    fun selectedId(context: Context, cache: ItineraryWidgetCache): String? {
        val selected = HomeWidgetPlugin.getData(context).getString(SELECTED_KEY, null)
        return selected?.takeIf { it in cache.dateIds }
            ?: cache.selectedId ?: cache.dates.firstOrNull()?.id
    }

    fun select(context: Context, id: String) {
        HomeWidgetPlugin.getData(context).edit().putString(SELECTED_KEY, id).apply()
    }
}
