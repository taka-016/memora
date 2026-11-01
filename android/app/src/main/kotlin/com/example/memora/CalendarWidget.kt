package com.example.memora

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import java.io.File
import java.time.LocalDate
import org.json.JSONObject

private const val CALENDAR_CACHE_KEY = "memora_widget_calendar_cache"
private const val CALENDAR_SELECTED_DATE_KEY = "memora_widget_calendar_selected_date"
private val DATE_PARAMETER = ActionParameters.Key<String>("date")

class CalendarWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CalendarWidget>() {
    override val glanceAppWidget = CalendarWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE &&
            !intent.getBooleanExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, false)) {
            AndroidWidgetUpdateFallbackScheduler.schedule(context)
            AndroidWidgetUpdateFallbackScheduler.recoverIfOverdue(context)
            requestCalendarRefresh(context)
        }
    }
}

class CalendarWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { CalendarContent(context, currentState()) }
    }
}

@Composable
private fun CalendarContent(context: Context, state: HomeWidgetGlanceState) {
    val prefs = state.preferences
    val groupId = prefs.getString("memora_widget_target_group_id", null).orEmpty()
    val cache = runCatching {
        val path = prefs.getString(CALENDAR_CACHE_KEY, null) ?: return@runCatching null
        JSONObject(File(path).readText(Charsets.UTF_8)).takeIf {
            it.optString("groupId") == groupId &&
                it.optString("sourceMode") == BuildConfig.RESOLVED_APP_MODE
        }
    }.getOrNull()
    Column(GlanceModifier.fillMaxSize().background(Color.White).padding(8.dp)) {
        if (groupId.isEmpty()) {
            CalendarMessage("表示対象グループを設定してください", actionStartActivity<MainActivity>(
                context, Uri.parse("memoraWidget://openSettings")))
        } else if (cache == null) {
            CalendarMessage("タップしてカレンダーを読み込む", calendarRefreshAction())
        } else {
            val month = LocalDate.parse(cache.getString("month"))
            val today = LocalDate.now()
            val selected = runCatching {
                LocalDate.parse(prefs.getString(CALENDAR_SELECTED_DATE_KEY, null))
            }.getOrNull()?.takeIf { it.year == month.year && it.month == month.month }
                ?: today.takeIf { it.year == month.year && it.month == month.month }
                ?: month
            val days = cache.getJSONArray("days")
            CalendarHeader(context, groupId, month, selected)
            Row(GlanceModifier.fillMaxWidth().height(20.dp)) {
                listOf("日", "月", "火", "水", "木", "金", "土").forEachIndexed { index, label ->
                    Text(label, modifier = GlanceModifier.defaultWeight(),
                        style = TextStyle(fontSize = 11.sp, textAlign = TextAlign.Center,
                            color = ColorProvider(dayColor(index))))
                }
            }
            val rows = days.length() / 7
            val rowHeight = ((LocalSize.current.height.value - 156f) / rows).coerceIn(24f, 64f)
            val compact = rowHeight < 44f
            val visibleCount = if (rowHeight >= 34f) 2 else 1
            Column(GlanceModifier.fillMaxWidth().background(Color(0xFFE5E7EB))) {
                repeat(rows) { row ->
                    Row(GlanceModifier.fillMaxWidth().height(rowHeight.dp)) {
                        repeat(7) { column ->
                            val day = days.getJSONObject(row * 7 + column)
                            val date = LocalDate.parse(day.getString("date"))
                            val events = day.getJSONArray("events")
                            Column(GlanceModifier.defaultWeight().fillMaxHeight().padding(1.dp)
                                .background(if (date == selected) Color(0xFFDCEBFF) else Color.White)
                                .clickable(actionRunCallback<SelectCalendarDayAction>(
                                    actionParametersOf(DATE_PARAMETER to date.toString())))
                                .padding(if (compact) 1.dp else 2.dp)) {
                                Text(text = "${date.dayOfMonth}" + if (events.length() > visibleCount) " +${events.length() - visibleCount}" else "",
                                    maxLines = 1, modifier = GlanceModifier.fillMaxWidth().height(if (compact) 12.dp else 16.dp),
                                    style = TextStyle(fontSize = if (compact) 9.sp else 10.sp, textAlign = TextAlign.Center,
                                        fontWeight = if (date == today) FontWeight.Bold else FontWeight.Normal,
                                        color = ColorProvider(if (date.month != month.month) Color.Gray else dayColor(column))))
                                repeat(minOf(visibleCount, events.length())) { index ->
                                    val event = events.getJSONObject(index)
                                    Text(event.getString("title"), maxLines = 1,
                                        modifier = GlanceModifier.fillMaxWidth().height(if (compact) 10.dp else 12.dp)
                                            .background(parseColor(event.optString("color"))),
                                        style = TextStyle(fontSize = if (compact) 8.sp else 9.sp,
                                            color = ColorProvider(parseColor(event.optString("textColor")))))
                                }
                            }
                        }
                    }
                }
            }
            Row(GlanceModifier.fillMaxWidth().height(24.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("${selected.monthValue}月${selected.dayOfMonth}日", modifier = GlanceModifier.defaultWeight(),
                    style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Bold))
                Text("更新", modifier = GlanceModifier.clickable(calendarRefreshAction()).padding(4.dp),
                    style = TextStyle(fontSize = 11.sp))
            }
            val selectedDay = (0 until days.length()).map { days.getJSONObject(it) }
                .firstOrNull { it.getString("date") == selected.toString() }
            val events = selectedDay?.getJSONArray("events")
            if (events == null || events.length() == 0) {
                Text("予定はありません", style = TextStyle(fontSize = 12.sp))
            } else {
                LazyColumn(GlanceModifier.fillMaxWidth().defaultWeight()) {
                    items((0 until events.length()).map { events.getJSONObject(it) }) { event ->
                        Row(GlanceModifier.fillMaxWidth().clickable(openCalendarAction(context, groupId, selected))
                            .padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(event.getString("timeLabel"), modifier = GlanceModifier.width(72.dp),
                                maxLines = 2, style = TextStyle(fontSize = 10.sp, color = ColorProvider(Color.DarkGray)))
                            Box(GlanceModifier.width(3.dp).height(28.dp).background(parseColor(event.optString("color")))) {}
                            Text(event.getString("title"), modifier = GlanceModifier.defaultWeight().padding(start = 6.dp),
                                maxLines = 2, style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Bold))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CalendarHeader(context: Context, groupId: String, month: LocalDate, selected: LocalDate) {
    Row(GlanceModifier.fillMaxWidth().height(36.dp), verticalAlignment = Alignment.CenterVertically) {
        HeaderButton("今日", calendarRefreshAction(LocalDate.now()))
        HeaderButton("‹", calendarRefreshAction(month.minusMonths(1)))
        Text("${month.year}年${month.monthValue}月", modifier = GlanceModifier.defaultWeight()
            .clickable(openCalendarAction(context, groupId, selected)),
            maxLines = 1, style = TextStyle(fontSize = 16.sp, textAlign = TextAlign.Center, fontWeight = FontWeight.Bold))
        HeaderButton("›", calendarRefreshAction(month.plusMonths(1)))
        HeaderButton("＋", openCalendarAction(context, groupId, selected, true))
    }
}

@Composable
private fun HeaderButton(label: String, action: Action) {
    Box(GlanceModifier.width(36.dp).fillMaxHeight().clickable(action), contentAlignment = Alignment.Center) {
        Text(label, style = TextStyle(fontSize = if (label == "今日") 12.sp else 24.sp))
    }
}

@Composable
private fun CalendarMessage(message: String, action: Action) {
    Box(GlanceModifier.fillMaxSize().clickable(action), contentAlignment = Alignment.Center) {
        Text(message, style = TextStyle(fontSize = 13.sp))
    }
}

private fun dayColor(column: Int) = when (column) {
    0 -> Color(0xFFE53935)
    6 -> Color(0xFF2962FF)
    else -> Color(0xFF222222)
}

private fun parseColor(value: String): Color = runCatching {
    Color(android.graphics.Color.parseColor(value))
}.getOrDefault(Color.Gray)

private fun openCalendarAction(context: Context, groupId: String, date: LocalDate, create: Boolean = false) =
    actionStartActivity<MainActivity>(context, Uri.parse(
        "memoraWidget://openCalendar?groupId=${Uri.encode(groupId)}&date=$date&create=$create"))

private fun calendarRefreshAction(date: LocalDate? = null) = actionRunCallback<RefreshCalendarAction>(
    actionParametersOf(DATE_PARAMETER to (date?.toString() ?: "")))

private fun requestCalendarRefresh(context: Context, date: String = "") {
    HomeWidgetBackgroundIntent.getBroadcast(context,
        Uri.parse("memoraWidget://calendarRefresh?date=$date")).send()
}

class RefreshCalendarAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        requestCalendarRefresh(context, parameters[DATE_PARAMETER].orEmpty())
    }
}

class SelectCalendarDayAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val date = parameters[DATE_PARAMETER] ?: return
        val prefs = HomeWidgetPlugin.getData(context)
        val month = runCatching {
            val cache = JSONObject(File(prefs.getString(CALENDAR_CACHE_KEY, "")!!).readText())
            LocalDate.parse(cache.getString("month"))
        }.getOrNull() ?: return
        val selected = LocalDate.parse(date)
        if (selected.month != month.month || selected.year != month.year) {
            requestCalendarRefresh(context, date)
            return
        }
        prefs.edit().putString(CALENDAR_SELECTED_DATE_KEY, date).apply()
        CalendarWidget().updateAll(context)
    }
}
