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
import androidx.glance.layout.wrapContentWidth
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
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
    val selectedItineraryDateId = prefs.getString(SELECTED_ITINERARY_DATE_ID_KEY, null)
        ?: cache?.selectedItineraryDateId
    val selectedItineraryDate = cache?.itineraryDates
        ?.firstOrNull { it.id == selectedItineraryDateId }

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
                selectedItineraryDate == null -> EmptyMessage("表示できる旅程がありません")
                else -> ItineraryDateContent(selectedItineraryDate)
            }
            FooterRow(cache?.lastUpdatedAt, errorMessage)
        }
    }
}

@Composable
private fun HeaderRow() {
    Box(
        modifier = GlanceModifier.fillMaxWidth(),
        contentAlignment = Alignment.TopEnd,
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
    }
}

@Composable
private fun ItineraryDateContent(itineraryDate: WidgetItineraryDate) {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(60.dp),
    ) {
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.CenterStart,
        ) {
            ArrowButton("<", actionRunCallback<PreviousItineraryDateAction>())
        }
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            TripHeader(itineraryDate)
        }
        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.CenterEnd,
        ) {
            ArrowButton(">", actionRunCallback<NextItineraryDateAction>())
        }
    }
    Text(
        text = itineraryDate.dateLabel,
        maxLines = 1,
        style = TextStyle(fontSize = 12.sp),
    )
    Spacer(modifier = GlanceModifier.height(6.dp))
    if (itineraryDate.items.isEmpty()) {
        Text(text = "旅程項目がありません", style = TextStyle(fontSize = 14.sp))
        return
    }

    val listEntries = buildItineraryListEntries(itineraryDate.items)
    LazyColumn(modifier = GlanceModifier.fillMaxWidth()) {
        items(listEntries) { entry ->
            when (entry) {
                is WidgetItineraryListEntry.Item -> ItineraryItemRow(entry.item)
                WidgetItineraryListEntry.Divider -> ItineraryDivider()
            }
        }
    }
}

@Composable
private fun TripHeader(itineraryDate: WidgetItineraryDate) {
    Column(
        modifier = GlanceModifier.width(180.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = itineraryDate.tripName,
            maxLines = 1,
            style = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Bold),
        )
        Text(
            text = itineraryDate.tripPeriodLabel,
            maxLines = 1,
            style = TextStyle(fontSize = 11.sp),
        )
    }
}

@Composable
private fun ItineraryItemRow(item: WidgetItineraryItem) {
    val timeParts = item.timeLabel.split(" - ", limit = 2)
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ItineraryTimeColumn(timeParts, item.timeLabel)
        Text(
            text = item.name,
            modifier = GlanceModifier.wrapContentWidth(),
            maxLines = 2,
            style = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
private fun ItineraryTimeColumn(timeParts: List<String>, fallbackLabel: String) {
    Column(
        modifier = GlanceModifier.width(72.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (timeParts.size == 2) {
            TimeText(timeParts[0])
            TimeText("-")
            TimeText(timeParts[1])
        } else {
            TimeText(fallbackLabel)
        }
    }
}

@Composable
private fun TimeText(text: String) {
    Text(
        text = text,
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(12.dp),
        maxLines = 1,
        style = TextStyle(
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        ),
    )
}

@Composable
private fun ItineraryDivider() {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Color(0xFFE0E0E0)),
    ) {}
}

private fun buildItineraryListEntries(
    items: List<WidgetItineraryItem>,
): List<WidgetItineraryListEntry> = buildList {
    items.forEachIndexed { index, item ->
        add(WidgetItineraryListEntry.Item(item))
        if (index < items.lastIndex) {
            add(WidgetItineraryListEntry.Divider)
        }
    }
}

@Composable
private fun ArrowButton(
    text: String,
    action: androidx.glance.action.Action,
) {
    Box(
        modifier = GlanceModifier
            .width(48.dp)
            .height(48.dp)
            .clickable(action),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = TextStyle(fontSize = 30.sp, fontWeight = FontWeight.Bold),
        )
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

class PreviousItineraryDateAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        sendAction(context, "previous")
    }
}

class NextItineraryDateAction : ActionCallback {
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
            selectedItineraryDateId = root
                .optString("selectedItineraryDateId")
                .ifBlank { null },
            lastUpdatedAt = formatLastUpdatedAt(root.optString("lastUpdatedAt")),
            itineraryDates = root.optJSONArray("itineraryDates").toItineraryDates(),
        )
    }.getOrNull()
}

private fun JSONArray?.toItineraryDates(): List<WidgetItineraryDate> {
    if (this == null) {
        return emptyList()
    }
    return buildList {
        for (index in 0 until length()) {
            val itineraryDate = optJSONObject(index) ?: continue
            add(
                WidgetItineraryDate(
                    id = itineraryDate.optString("id"),
                    tripName = itineraryDate.optString("tripName"),
                    tripPeriodLabel = itineraryDate.optString("tripPeriodLabel"),
                    dateLabel = itineraryDate.optString("dateLabel"),
                    items = itineraryDate.optJSONArray("itineraryItems").toItems(),
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
    val selectedItineraryDateId: String?,
    val lastUpdatedAt: String,
    val itineraryDates: List<WidgetItineraryDate>,
)

private data class WidgetItineraryDate(
    val id: String,
    val tripName: String,
    val tripPeriodLabel: String,
    val dateLabel: String,
    val items: List<WidgetItineraryItem>,
)

private data class WidgetItineraryItem(
    val name: String,
    val timeLabel: String,
)

private sealed interface WidgetItineraryListEntry {
    data class Item(val item: WidgetItineraryItem) : WidgetItineraryListEntry
    object Divider : WidgetItineraryListEntry
}

private const val TARGET_GROUP_ID_KEY = "memora_widget_target_group_id"
private const val SELECTED_ITINERARY_DATE_ID_KEY =
    "memora_widget_selected_itinerary_date_id"
private const val ERROR_MESSAGE_KEY = "memora_widget_error_message"
private const val CACHE_FILE_KEY = "memora_widget_itinerary_cache"
