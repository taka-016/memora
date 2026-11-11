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
    val generation: String = lastUpdatedAt,
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
        if (path != cachePath || modifiedAt != file.lastModified() || length != file.length() ||
            !prefs.getString(pendingKey("action"), null).isNullOrEmpty()) {
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
                generation = root.optString("lastUpdatedAt"),
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

    private fun pendingKey(field: String) = "memora_widget_itinerary_pending_$field"

    fun cancelPendingNavigation(context: Context) {
        val edit = HomeWidgetPlugin.getData(context).edit()
        listOf("action", "source", "group", "generation").forEach { edit.remove(pendingKey(it)) }
        edit.apply()
    }

    fun rememberPendingNavigation(context: Context, cache: ItineraryWidgetCache, current: String?, action: String) {
        HomeWidgetPlugin.getData(context).edit()
            .putString(pendingKey("action"), action)
            .putString(pendingKey("source"), current.orEmpty())
            .putString(pendingKey("group"), cache.groupId)
            .putString(pendingKey("generation"), cache.generation)
            .putString(SELECTED_KEY, current.orEmpty()).apply()
        startLoading(context, if (action == "recent") null else current)
    }

    fun applyPendingNavigation(context: Context, cache: ItineraryWidgetCache) {
        val prefs = HomeWidgetPlugin.getData(context)
        val action = prefs.getString(pendingKey("action"), null).orEmpty()
        if (action.isEmpty()) return
        val pending = PendingItineraryNavigation(action,
            prefs.getString(pendingKey("source"), null).orEmpty(),
            prefs.getString(pendingKey("group"), null).orEmpty(),
            prefs.getString(pendingKey("generation"), null).orEmpty())
        val current = prefs.getString(SELECTED_KEY, null).orEmpty()
        if (pending.groupId != cache.groupId || pending.sourceId != current) {
            cancelPendingNavigation(context)
            return
        }
        if (pending.generation == cache.generation) {
            if (loadState(context, current) == WidgetLoadState.FAILED) cancelPendingNavigation(context)
            return
        }
        val target = pendingItineraryTarget(pending, cache, current)
        val edit = prefs.edit()
        if (target != null) edit.putString(SELECTED_KEY, target)
        listOf("action", "source", "group", "generation").forEach { edit.remove(pendingKey(it)) }
        edit.apply()
    }

    fun selectedId(context: Context, cache: ItineraryWidgetCache): String? {
        val selected = HomeWidgetPlugin.getData(context).getString(SELECTED_KEY, null)
        return selected?.takeIf { it in cache.dateIds }
            ?: cache.selectedId ?: cache.dates.firstOrNull()?.id
    }

    fun loadState(context: Context, selectedId: String?): WidgetLoadState {
        val prefs = HomeWidgetPlugin.getData(context)
        val pendingGroup = prefs.getString(pendingKey("group"), null)
        val pendingAction = prefs.getString(pendingKey("action"), null)
        val source = prefs.getString(pendingKey("source"), null)
        val key = if (pendingGroup == targetGroup(context) && source == selectedId && pendingAction == "recent") null else selectedId
        return WidgetLoadState.fromValue(prefs.getString(itineraryWidgetLoadStateKey(targetGroup(context), key), null))
    }

    fun startLoading(context: Context, selectedId: String?) {
        val groupId = targetGroup(context)
        if (groupId.isEmpty()) return
        HomeWidgetPlugin.getData(context).edit()
            .putString(itineraryWidgetLoadStateKey(groupId, selectedId), "loading").apply()
    }

    fun select(context: Context, id: String) {
        HomeWidgetPlugin.getData(context).edit().putString(SELECTED_KEY, id).apply()
    }
}
