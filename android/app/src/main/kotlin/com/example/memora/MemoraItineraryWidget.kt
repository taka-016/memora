package com.example.memora

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class MemoraItineraryWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MemoraItineraryWidget()
}

class MemoraItineraryWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            MemoraItineraryWidgetContent(context, currentState())
        }
    }
}

@Composable
private fun MemoraItineraryWidgetContent(
    context: Context,
    state: HomeWidgetGlanceState,
) {
    val prefs = state.preferences
    val targetGroupId = prefs.getString(TARGET_GROUP_ID_KEY, null).orEmpty()
    val errorMessage = prefs.getString(ERROR_MESSAGE_KEY, null).orEmpty()
    val cache = readCache(prefs.getString(CACHE_FILE_KEY, null))
    val selectedTripId = prefs.getString(SELECTED_TRIP_ID_KEY, null)
        ?: cache?.selectedTripId
    val selectedTrip = cache?.trips?.firstOrNull { it.id == selectedTripId }

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color.White)
            .padding(12.dp),
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            HeaderRow()
            Spacer(modifier = GlanceModifier.height(4.dp))
            when {
                targetGroupId.isEmpty() -> EmptyMessage("表示対象グループが未設定です")
                selectedTrip == null -> EmptyMessage("表示できる旅行がありません")
                else -> TripContent(selectedTrip)
            }
            FooterRow(cache?.lastUpdatedAt, errorMessage)
        }
    }
}

@Composable
private fun HeaderRow() {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "更新",
            modifier = GlanceModifier.clickable(
                actionRunCallback<RefreshWidgetAction>(),
            ),
            style = TextStyle(
                color = androidx.glance.unit.ColorProvider(Color(0xFF1565C0)),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
        Spacer(modifier = GlanceModifier.width(120.dp))
        Text(
            text = "<",
            modifier = GlanceModifier
                .padding(horizontal = 8.dp)
                .clickable(actionRunCallback<PreviousTripAction>()),
            style = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.Bold),
        )
        Spacer(modifier = GlanceModifier.width(12.dp))
        Text(
            text = ">",
            modifier = GlanceModifier
                .padding(horizontal = 8.dp)
                .clickable(actionRunCallback<NextTripAction>()),
            style = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
private fun TripContent(trip: WidgetTrip) {
    Text(
        text = trip.name,
        maxLines = 1,
        style = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Bold),
    )
    Text(
        text = trip.periodLabel,
        maxLines = 1,
        style = TextStyle(fontSize = 12.sp),
    )
    Spacer(modifier = GlanceModifier.height(6.dp))
    if (trip.items.isEmpty()) {
        Text(text = "旅程項目がありません", style = TextStyle(fontSize = 12.sp))
        return
    }

    Column {
        trip.items.take(3).forEach { item ->
            Text(
                text = "${item.timeLabel}  ${item.name}",
                maxLines = 1,
                style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Bold),
            )
            if (item.memo.isNotBlank()) {
                Text(
                    text = item.memo,
                    maxLines = 1,
                    style = TextStyle(fontSize = 11.sp),
                )
            }
        }
    }
}

@Composable
private fun EmptyMessage(message: String) {
    Box(
        modifier = GlanceModifier.fillMaxWidth(),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = message, style = TextStyle(fontSize = 13.sp))
    }
}

@Composable
private fun FooterRow(lastUpdatedAt: String?, errorMessage: String) {
    val message = when {
        errorMessage.isNotBlank() -> errorMessage
        !lastUpdatedAt.isNullOrBlank() -> "最終更新 $lastUpdatedAt"
        else -> ""
    }
    if (message.isBlank()) {
        return
    }
    Text(text = message, maxLines = 1, style = TextStyle(fontSize = 10.sp))
}

class RefreshWidgetAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        sendAction(context, "refresh")
    }
}

class PreviousTripAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        sendAction(context, "previous")
    }
}

class NextTripAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        sendAction(context, "next")
    }
}

private fun sendAction(context: Context, action: String) {
    HomeWidgetBackgroundIntent
        .getBroadcast(context, Uri.parse("memoraWidget://$action"))
        .send()
}

private fun readCache(path: String?): WidgetCache? {
    if (path.isNullOrBlank()) {
        return null
    }
    val file = File(path)
    if (!file.exists()) {
        return null
    }
    return runCatching {
        val root = JSONObject(file.readText(Charsets.UTF_8))
        WidgetCache(
            selectedTripId = root.optString("selectedTripId").ifBlank { null },
            lastUpdatedAt = formatLastUpdatedAt(root.optString("lastUpdatedAt")),
            trips = root.optJSONArray("trips").toTrips(),
        )
    }.getOrNull()
}

private fun JSONArray?.toTrips(): List<WidgetTrip> {
    if (this == null) {
        return emptyList()
    }
    return buildList {
        for (index in 0 until length()) {
            val trip = optJSONObject(index) ?: continue
            add(
                WidgetTrip(
                    id = trip.optString("id"),
                    name = trip.optString("name"),
                    periodLabel = trip.optString("periodLabel"),
                    items = trip.optJSONArray("itineraryItems").toItems(),
                ),
            )
        }
    }
}

private fun JSONArray?.toItems(): List<WidgetItineraryItem> {
    if (this == null) {
        return emptyList()
    }
    return buildList {
        for (index in 0 until length()) {
            val item = optJSONObject(index) ?: continue
            add(
                WidgetItineraryItem(
                    name = item.optString("name"),
                    timeLabel = item.optString("timeLabel"),
                    memo = item.optString("memo"),
                ),
            )
        }
    }
}

private fun formatLastUpdatedAt(value: String): String {
    if (value.isBlank()) {
        return ""
    }
    return value.replace("T", " ").take(16)
}

private data class WidgetCache(
    val selectedTripId: String?,
    val lastUpdatedAt: String,
    val trips: List<WidgetTrip>,
)

private data class WidgetTrip(
    val id: String,
    val name: String,
    val periodLabel: String,
    val items: List<WidgetItineraryItem>,
)

private data class WidgetItineraryItem(
    val name: String,
    val timeLabel: String,
    val memo: String,
)

private const val TARGET_GROUP_ID_KEY = "memora_widget_target_group_id"
private const val SELECTED_TRIP_ID_KEY = "memora_widget_selected_trip_id"
private const val ERROR_MESSAGE_KEY = "memora_widget_error_message"
private const val CACHE_FILE_KEY = "memora_widget_itinerary_cache"
