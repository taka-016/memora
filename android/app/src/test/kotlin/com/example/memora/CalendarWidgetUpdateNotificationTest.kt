package com.example.memora

import android.app.Application
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File
import java.time.LocalDate

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE, application = Application::class)
class CalendarWidgetUpdateNotificationTest {
    private val context = RuntimeEnvironment.getApplication()
    private val notification = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)

    @Test
    fun `取得済みの月へ移動しても共有キャッシュが変われば再描画を要求する`() {
        val file = File(context.filesDir, "shared-calendar-test")
        file.writeText("予定")
        val current = LocalDate.of(2026, 11, 1)
        val previous = current.minusMonths(1)
        val monthly = CalendarWidgetMonth(current, emptyList(),
            sourceFiles = mapOf(file.path to file.lastModified()))
        val months = mapOf(previous to monthly, current to monthly, current.plusMonths(1) to monthly)
        assertFalse(needsCalendarWidgetRefresh(previous, current, months))
        assertFalse(needsCalendarWidgetRefresh(current, current.plusDays(1), months))
        assertTrue(file.setLastModified(file.lastModified() + 1000))
        assertTrue(needsCalendarWidgetRefresh(previous, current, months))
        assertTrue(needsCalendarWidgetRefresh(current, current.plusDays(1), months))
    }

    @Test
    fun `自動更新通知を受け付けてから1分間は後続の通知を無視する`() {
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 120_000))
        assertFalse(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 120_001))
        assertFalse(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 179_999))
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 180_000))
        assertFalse(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 180_001))
    }

    @Test
    fun `間隔内の自動通知でも新しいウィジェットを端末のキャッシュで描画する`() {
        val drawn = mutableListOf<Int>()
        val receiver = object : CalendarWidgetReceiver() {
            override fun updateWidget(
                context: Context,
                manager: AppWidgetManager,
                widgetId: Int,
                forceFull: Boolean,
            ) {
                drawn.add(widgetId)
            }
        }
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification))
        val addedWidget = Intent(notification)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(7))

        receiver.receive(context, addedWidget)

        assertEquals(listOf(7), drawn)
        assertFalse(shadowOf(context).broadcastIntents.any {
            it.component?.className == AndroidWidgetBackgroundReceiver::class.java.name
        })
    }

    @Test
    fun `再描画とウィジェット操作は自動更新通知の受付時刻を変更しない`() {
        val redraw = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            .putExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, true)
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 120_000))
        assertTrue(shouldReceiveCalendarWidgetIntent(context, redraw, nowMillis = 150_000))
        assertTrue(shouldReceiveCalendarWidgetIntent(
            context, Intent(CALENDAR_REFRESH_ACTION), nowMillis = 160_000,
        ))
        assertTrue(shouldReceiveCalendarWidgetIntent(
            context, Intent(CALENDAR_SELECT_ACTION), nowMillis = 170_000,
        ))
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 180_000))
    }
}
