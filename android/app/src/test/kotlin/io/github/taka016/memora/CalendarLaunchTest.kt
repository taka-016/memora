package io.github.taka016.memora

import android.app.Application
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE, application = Application::class)
class CalendarLaunchTest {
    @Test
    fun `日時から開く要求を一度だけ受け取り起動済みでも次の要求を受け取る`() {
        val inbox = CalendarLaunchInbox()
        val date = Intent(Intent.ACTION_VIEW, Uri.parse("content://com.android.calendar/time/1796086800000"))
        assertTrue(inbox.receive(date))
        assertEquals(1796086800000L, inbox.takePending()!!["begin"])
        assertNull(inbox.takePending())
        assertTrue(inbox.receive(date))
        assertEquals("view", inbox.takePending()!!["action"])
    }

    @Test
    fun `予定追加の内容と終日フラグを保持する`() {
        val inbox = CalendarLaunchInbox()
        val intent = Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)
            .putExtra(CalendarContract.Events.TITLE, "家族の予定")
            .putExtra(CalendarContract.Events.DESCRIPTION, "持ち物")
            .putExtra(CalendarContract.Events.EVENT_LOCATION, "公園")
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, 1796086800000L)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, 1796173200000L)
            .putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, true)
        assertTrue(inbox.receive(intent))
        val payload = inbox.takePending()!!
        assertEquals("create", payload["action"])
        assertEquals("家族の予定", payload["title"])
        assertEquals("持ち物", payload["description"])
        assertEquals("公園", payload["location"])
        assertEquals(true, payload["allDay"])
        assertEquals(1796173200000L, payload["end"])
    }

    @Test
    fun `MIME型だけの予定追加とカレンダーアプリ指定の起動を受け取る`() {
        val inbox = CalendarLaunchInbox()
        assertTrue(inbox.receive(Intent(Intent.ACTION_INSERT).setType("vnd.android.cursor.dir/event")))
        assertEquals("create", inbox.takePending()!!["action"])
        assertTrue(inbox.receive(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_CALENDAR)))
        assertEquals("view", inbox.takePending()!!["action"])
    }

    @Test
    fun `他アプリの予定詳細や不正な日時では保留中の要求を上書きしない`() {
        val inbox = CalendarLaunchInbox()
        inbox.receive(Intent(Intent.ACTION_INSERT).setType("vnd.android.cursor.dir/event"))
        for (uri in listOf(
            "content://com.android.calendar/events/42",
            "content://other/time/123",
            "content://com.android.calendar/time/invalid",
        )) {
            assertFalse(inbox.receive(Intent(Intent.ACTION_VIEW, Uri.parse(uri))))
        }
        assertEquals("create", inbox.takePending()!!["action"])
    }
}
