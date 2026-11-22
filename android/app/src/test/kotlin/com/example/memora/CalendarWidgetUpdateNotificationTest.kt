package com.example.memora

import android.app.Application
import android.appwidget.AppWidgetManager
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE, application = Application::class)
class CalendarWidgetUpdateNotificationTest {
    private val context = RuntimeEnvironment.getApplication()
    private val notification = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)

    @Test
    fun `自動更新通知を受け付けてから1分間は後続の通知を無視する`() {
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 120_000))
        assertFalse(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 120_001))
        assertFalse(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 179_999))
        assertTrue(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 180_000))
        assertFalse(shouldReceiveCalendarWidgetIntent(context, notification, nowMillis = 180_001))
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
