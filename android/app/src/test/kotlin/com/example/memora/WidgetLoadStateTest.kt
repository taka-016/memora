package com.example.memora

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetLoadStateTest {
    @Test
    fun `旅程はグループと選択日ごとに読み込み状態を区別する`() {
        assertEquals("memora_widget_itinerary_load_group_trip_2026-11-08",
            itineraryWidgetLoadStateKey("group", "trip_2026-11-08"))
        assertEquals("memora_widget_itinerary_load_other_recent",
            itineraryWidgetLoadStateKey("other", null))
    }

    @Test
    fun `取得中は読み込み中を表示し失敗後だけ再試行を案内する`() {
        for (value in listOf("loading", "loading:request-1")) {
            val state = WidgetLoadState.fromValue(value)
            assertEquals("読み込み中…", state.message)
            assertFalse(state.canRetry)
        }
        val failed = WidgetLoadState.fromValue("failed")
        assertEquals("読み込めませんでした。タップして再試行", failed.message)
        assertTrue(failed.canRetry)
        assertTrue(WidgetLoadState.fromValue(null).canRetry)
    }

    @Test
    fun `同じ月の取得状態を共有し他の月やグループと区別する`() {
        assertEquals("memora_widget_calendar_load_group_2026-11-01",
            calendarWidgetLoadStateKey("group", LocalDate.of(2026, 11, 8)))
        assertEquals("memora_widget_calendar_load_other_2026-12-01",
            calendarWidgetLoadStateKey("other", LocalDate.of(2026, 12, 31)))
    }
}
