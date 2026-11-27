package io.github.taka016.memora

import android.app.Application
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CalendarContract
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class CalendarIntentResolutionTest {
    @Test
    fun `日時のMIME型付き呼び出しでもMemoraが起動候補になる`() {
        val context = RuntimeEnvironment.getApplication()
        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(
            Uri.parse("content://com.android.calendar/time/1796086800000"),
            "time/epoch",
        )
        val candidates = context.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        assertTrue(candidates.any { it.activityInfo.name == MainActivity::class.java.name })
    }

    @Test
    fun `日付表示と予定追加でMemoraが起動候補になる`() {
        val context = RuntimeEnvironment.getApplication()
        val intents = listOf(
            Intent(Intent.ACTION_VIEW, Uri.parse("content://com.android.calendar/time/1796086800000")),
            Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI),
            Intent(Intent.ACTION_INSERT).setType("vnd.android.cursor.dir/event"),
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_CALENDAR),
        )
        for (intent in intents) {
            val candidates = context.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            assertTrue("起動候補なし: $intent", candidates.any { it.activityInfo.name == MainActivity::class.java.name })
        }
    }
}
