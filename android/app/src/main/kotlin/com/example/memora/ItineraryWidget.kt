package com.example.memora

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.appwidget.AppWidgetManager
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
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
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class ItineraryWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ItineraryWidget>() {
    override val glanceAppWidget = ItineraryWidget()

    override fun onReceive(context: Context, intent: Intent) {
        val shouldRecover = intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE &&
            !intent.getBooleanExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, false)
        if (shouldRecover) {
            AndroidWidgetUpdateFallbackScheduler.schedule(context)
        }
        super.onReceive(context, intent)
        if (shouldRecover) {
            AndroidWidgetUpdateFallbackScheduler.recoverIfOverdue(context)
        }
    }
}

class ItineraryWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            ItineraryWidgetContent(context, currentState())
        }
    }
}

@Composable
private fun ItineraryWidgetContent(
    context: Context,
    state: HomeWidgetGlanceState,
) {
    val prefs = state.preferences
    val targetGroupId = prefs.getString(TARGET_GROUP_ID_KEY, null).orEmpty()
    val cache = readCache(prefs.getString(CACHE_FILE_KEY, null))
    val selectedItineraryDateId = cache?.selectedItineraryDateId
    val selectedItineraryDate = cache?.itineraryDates
        ?.firstOrNull { it.id == selectedItineraryDateId }
        ?: cache?.itineraryDates?.firstOrNull()

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color.White),
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(WIDGET_PADDING_DP.dp),
        ) {
            Spacer(modifier = GlanceModifier.height(CONTENT_TOP_SPACE_DP.dp))
            when {
                targetGroupId.isEmpty() -> EmptyMessage("表示対象グループが未設定です")
                selectedItineraryDate == null -> EmptyMessage("表示できる旅程がありません")
                else -> ItineraryDateContent(context, selectedItineraryDate)
            }
        }
        HeaderRow(cache?.lastUpdatedAt)
    }
}

@Composable
private fun HeaderRow(lastUpdatedAt: String?) {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(end = REFRESH_BUTTON_END_PADDING_DP.dp),
        contentAlignment = Alignment.TopEnd,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (!lastUpdatedAt.isNullOrBlank()) {
                LastUpdatedText(lastUpdatedAt)
                Spacer(modifier = GlanceModifier.width(HEADER_ITEM_SPACE_DP.dp))
            }
            Box(
                modifier = GlanceModifier
                    .width(REFRESH_BUTTON_WIDTH_DP.dp)
                    .height(REFRESH_BUTTON_HEIGHT_DP.dp)
                    .clickable(actionRunCallback<RefreshWidgetAction>()),
                contentAlignment = Alignment.TopStart,
            ) {
                RefreshIcon()
            }
        }
    }
}

@Composable
private fun LastUpdatedText(lastUpdatedAt: String) {
    Text(
        text = "最終更新 $lastUpdatedAt",
        modifier = GlanceModifier.padding(top = LAST_UPDATED_TOP_PADDING_DP.dp),
        maxLines = 1,
        style = TextStyle(fontSize = 10.sp),
    )
}

@Composable
private fun RefreshIcon() {
    Column {
        Spacer(modifier = GlanceModifier.height(REFRESH_ICON_TOP_SPACE_DP.dp))
        Image(
            provider = ImageProvider(R.drawable.ic_widget_refresh),
            contentDescription = "更新",
            modifier = GlanceModifier
                .width(REFRESH_ICON_SIZE_DP.dp)
                .height(REFRESH_ICON_SIZE_DP.dp),
        )
    }
}

@Composable
private fun ColumnScope.ItineraryDateContent(
    context: Context,
    itineraryDate: WidgetItineraryDate,
) {
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
            TripHeader(context, itineraryDate)
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
        Spacer(modifier = GlanceModifier.height(RECENT_BUTTON_TOP_SPACE_DP.dp))
        RecentItineraryDateActionRow()
        return
    }

    ItineraryList(context, itineraryDate)
    Spacer(modifier = GlanceModifier.height(RECENT_BUTTON_TOP_SPACE_DP.dp))
    RecentItineraryDateActionRow()
}

@Composable
private fun ColumnScope.ItineraryList(
    context: Context,
    itineraryDate: WidgetItineraryDate,
) {
    val tripId = itineraryDate.tripId
    val items = itineraryDate.items
    val listEntries = buildItineraryListEntries(items)
    LazyColumn(
        modifier = GlanceModifier
            .fillMaxWidth()
            .defaultWeight(),
    ) {
        items(listEntries) { entry ->
            Box(modifier = openTripModifier(context, tripId)) {
                when (entry) {
                    is WidgetItineraryListEntry.Item -> ItineraryItemRow(entry.item)
                    WidgetItineraryListEntry.Divider -> ItineraryDivider()
                }
            }
        }
    }
}

@Composable
private fun TripHeader(
    context: Context,
    itineraryDate: WidgetItineraryDate,
) {
    Column(
        modifier = GlanceModifier
            .width(180.dp)
            .clickable(openTripAction(context, itineraryDate.tripId)),
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

private fun openTripModifier(
    context: Context,
    tripId: String,
) = GlanceModifier
    .fillMaxWidth()
    .clickable(openTripAction(context, tripId))

private fun openTripAction(
    context: Context,
    tripId: String,
) = actionStartActivity<MainActivity>(
    context,
    Uri.parse("memoraWidget://openTrip?tripId=${Uri.encode(tripId)}"),
)

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
            TimeText("|")
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
            .height(TIME_TEXT_HEIGHT_DP.dp),
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
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        Spacer(modifier = GlanceModifier.height(DIVIDER_TOP_SPACE_DP.dp))
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .height(1.dp)
                .background(Color(0xFFE0E0E0)),
        ) {}
        Spacer(modifier = GlanceModifier.height(DIVIDER_BOTTOM_SPACE_DP.dp))
    }
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
            .width(ARROW_BUTTON_WIDTH_DP.dp)
            .height(ARROW_BUTTON_HEIGHT_DP.dp)
            .clickable(action),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = TextStyle(
                fontSize = ARROW_BUTTON_FONT_SP.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun RecentItineraryDateActionRow() {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(RECENT_BUTTON_HEIGHT_DP.dp),
        contentAlignment = Alignment.TopStart,
    ) {
        RecentItineraryDateButton()
    }
}

@Composable
private fun RecentItineraryDateButton() {
    Box(
        modifier = GlanceModifier
            .width(RECENT_BUTTON_WIDTH_DP.dp)
            .height(RECENT_BUTTON_HEIGHT_DP.dp)
            .clickable(actionRunCallback<RecentItineraryDateAction>()),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "直近の旅程",
            maxLines = 1,
            style = TextStyle(
                fontSize = RECENT_BUTTON_FONT_SP.sp,
                fontWeight = FontWeight.Bold,
            ),
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

class RefreshWidgetAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        sendAction(context, "refresh")
    }
}

class RecentItineraryDateAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        sendAction(context, "recent")
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
                    tripId = itineraryDate.optString("tripId"),
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
    return value.replace("-", "/").replace("T", " ").take(16)
}

private data class WidgetCache(
    val selectedItineraryDateId: String?,
    val lastUpdatedAt: String,
    val itineraryDates: List<WidgetItineraryDate>,
)

private data class WidgetItineraryDate(
    val id: String,
    val tripId: String,
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
private const val CACHE_FILE_KEY = "memora_widget_itinerary_cache"
private const val WIDGET_PADDING_DP = 8
private const val CONTENT_TOP_SPACE_DP = 10
private const val TIME_TEXT_HEIGHT_DP = 12
private const val DIVIDER_TOP_SPACE_DP = 4
private const val DIVIDER_BOTTOM_SPACE_DP = 2
private const val HEADER_ITEM_SPACE_DP = 0
private const val LAST_UPDATED_TOP_PADDING_DP = 6
private const val REFRESH_BUTTON_WIDTH_DP = 36
private const val REFRESH_BUTTON_HEIGHT_DP = 28
private const val REFRESH_BUTTON_END_PADDING_DP = 8
private const val REFRESH_ICON_SIZE_DP = 24
private const val REFRESH_ICON_TOP_SPACE_DP = 5
private const val ARROW_BUTTON_WIDTH_DP = 56
private const val ARROW_BUTTON_HEIGHT_DP = 64
private const val ARROW_BUTTON_FONT_SP = 36
private const val RECENT_BUTTON_WIDTH_DP = 76
private const val RECENT_BUTTON_HEIGHT_DP = 22
private const val RECENT_BUTTON_TOP_SPACE_DP = 4
private const val RECENT_BUTTON_FONT_SP = 10
