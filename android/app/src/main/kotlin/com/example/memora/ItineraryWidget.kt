package com.example.memora

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
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
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import java.io.File
import java.util.UUID
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

class ItineraryWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ItineraryWidget()
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
    val selectedItineraryDateId = prefs.getString(SELECTED_ITINERARY_DATE_ID_KEY, null)
        ?: cache?.selectedItineraryDateId
    val selectedItineraryDate = cache?.itineraryDates
        ?.firstOrNull { it.id == selectedItineraryDateId }

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
                else -> ItineraryDateContent(selectedItineraryDate)
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

    ItineraryList(itineraryDate.items)
}

@Composable
private fun ItineraryList(items: List<WidgetItineraryItem>) {
    val listEntries = buildItineraryListEntries(items)
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
        runWidgetAction(context, WIDGET_ACTION_REFRESH)
    }
}

class PreviousItineraryDateAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        runWidgetAction(context, WIDGET_ACTION_PREVIOUS)
    }
}

class NextItineraryDateAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters,
    ) {
        runWidgetAction(context, WIDGET_ACTION_NEXT)
    }
}

private suspend fun runWidgetAction(context: Context, action: String) {
    val actionId = buildActionId(action)
    val uri = Uri.Builder()
        .scheme(WIDGET_URI_SCHEME)
        .authority(action)
        .appendQueryParameter(ACTION_ID_QUERY_PARAMETER, actionId)
        .build()
    val result = runCatching {
        if (!enqueueBackgroundWorkAndWait(context, uri)) {
            null
        } else {
            waitForActionResult(context, actionId)
        }
    }.getOrNull()
    resolveNotificationMessage(action, result)?.let { message ->
        showNotification(context, message)
    }
    clearActionResult(context, actionId)
}

private fun buildActionId(action: String): String {
    return "$action-${System.currentTimeMillis()}-${UUID.randomUUID()}"
}

private suspend fun enqueueBackgroundWorkAndWait(context: Context, uri: Uri): Boolean {
    val workManager = WorkManager.getInstance(context.applicationContext)
    val request = OneTimeWorkRequestBuilder<HomeWidgetBackgroundWorker>()
        .setInputData(
            Data.Builder()
                .putString(HOME_WIDGET_WORKER_URI_DATA_KEY, uri.toString())
                .build(),
        )
        .build()
    withContext(Dispatchers.IO) {
        workManager.enqueue(request).result.get()
    }
    repeat(BACKGROUND_WORK_WAIT_ATTEMPTS) {
        val workInfo = withContext(Dispatchers.IO) {
            workManager.getWorkInfoById(request.id).get()
        }
        if (workInfo?.state?.isFinished == true) {
            return workInfo.state == WorkInfo.State.SUCCEEDED
        }
        delay(BACKGROUND_WAIT_INTERVAL_MILLIS)
    }
    return false
}

private suspend fun waitForActionResult(
    context: Context,
    actionId: String,
): WidgetActionResult? {
    repeat(ACTION_RESULT_WAIT_ATTEMPTS) {
        val result = readActionResult(context, actionId)
        if (result != null) {
            return result
        }
        delay(BACKGROUND_WAIT_INTERVAL_MILLIS)
    }
    return null
}

private suspend fun readActionResult(
    context: Context,
    actionId: String,
): WidgetActionResult? = withContext(Dispatchers.IO) {
    val raw = context
        .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        .getString(buildActionResultKey(actionId), null)
        ?: return@withContext null
    runCatching {
        val root = JSONObject(raw)
        WidgetActionResult(
            notificationType = root.optString("notificationType"),
            message = root.optString("message").ifBlank { null },
            isSuccess = root.optBoolean("isSuccess", false),
        )
    }.getOrNull()
}

private fun resolveNotificationMessage(
    action: String,
    result: WidgetActionResult?,
): String? {
    if (result == null) {
        return failureMessageFor(action)
    }
    if (result.notificationType != NOTIFICATION_TYPE) {
        return null
    }
    if (!result.message.isNullOrBlank()) {
        return result.message
    }
    return if (result.isSuccess) null else failureMessageFor(action)
}

private fun failureMessageFor(action: String): String {
    return if (action == WIDGET_ACTION_REFRESH) {
        "更新に失敗しました"
    } else {
        "切り替えに失敗しました"
    }
}

private fun showNotification(context: Context, message: String) {
    val applicationContext = context.applicationContext
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
        applicationContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
        PackageManager.PERMISSION_GRANTED
    ) {
        return
    }
    val notificationManager = applicationContext
        .getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        notificationManager.createNotificationChannel(
            NotificationChannel(
                WIDGET_NOTIFICATION_CHANNEL_ID,
                "Androidウィジェット",
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )
    }
    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        Notification.Builder(applicationContext, WIDGET_NOTIFICATION_CHANNEL_ID)
    } else {
        @Suppress("DEPRECATION")
        Notification.Builder(applicationContext)
    }
    builder
        .setSmallIcon(R.drawable.ic_widget_refresh)
        .setContentTitle("memora")
        .setContentText(message)
        .setPriority(Notification.PRIORITY_HIGH)
        .setAutoCancel(true)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        builder.setTimeoutAfter(NOTIFICATION_TIMEOUT_MILLIS)
    }
    notificationManager.notify(WIDGET_NOTIFICATION_ID, builder.build())
}

private suspend fun clearActionResult(context: Context, actionId: String) {
    withContext(Dispatchers.IO) {
        context
            .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .remove(buildActionResultKey(actionId))
            .commit()
    }
}

private fun buildActionResultKey(actionId: String): String {
    return "$ACTION_RESULT_KEY_PREFIX$actionId"
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
    return value.replace("-", "/").replace("T", " ").take(16)
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

private data class WidgetActionResult(
    val notificationType: String,
    val message: String?,
    val isSuccess: Boolean,
)

private sealed interface WidgetItineraryListEntry {
    data class Item(val item: WidgetItineraryItem) : WidgetItineraryListEntry
    object Divider : WidgetItineraryListEntry
}

private const val TARGET_GROUP_ID_KEY = "memora_widget_target_group_id"
private const val SELECTED_ITINERARY_DATE_ID_KEY =
    "memora_widget_selected_itinerary_date_id"
private const val ACTION_RESULT_KEY_PREFIX = "memora_widget_action_result_"
private const val CACHE_FILE_KEY = "memora_widget_itinerary_cache"
private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
private const val HOME_WIDGET_WORKER_URI_DATA_KEY = "uri_data"
private const val WIDGET_URI_SCHEME = "memoraWidget"
private const val ACTION_ID_QUERY_PARAMETER = "actionId"
private const val NOTIFICATION_TYPE = "notification"
private const val WIDGET_NOTIFICATION_CHANNEL_ID = "memora_widget_heads_up"
private const val WIDGET_NOTIFICATION_ID = 1001
private const val NOTIFICATION_TIMEOUT_MILLIS = 3000L
private const val WIDGET_ACTION_REFRESH = "refresh"
private const val WIDGET_ACTION_PREVIOUS = "previous"
private const val WIDGET_ACTION_NEXT = "next"
private const val BACKGROUND_WORK_WAIT_ATTEMPTS = 50
private const val ACTION_RESULT_WAIT_ATTEMPTS = 50
private const val BACKGROUND_WAIT_INTERVAL_MILLIS = 100L
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
