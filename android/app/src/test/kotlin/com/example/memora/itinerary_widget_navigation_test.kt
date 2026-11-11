package com.example.memora

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ItineraryWidgetNavigationTest {
    private fun cache(ids: List<String>, generation: String = "new") = ItineraryWidgetCache(
        groupId = "g", selectedId = "a", recentId = "b", dateIds = ids,
        dates = emptyList(), lastUpdatedAt = "日時", generation = generation,
    )

    @Test
    fun `一覧の境界で要求した翌日は取得後の一覧から選ぶ`() {
        val pending = PendingItineraryNavigation("next", "a", "g", "old")
        assertEquals("b", pendingItineraryTarget(pending, cache(listOf("a", "b")), "a"))
        assertNull(pendingItineraryTarget(pending, cache(listOf("a"), "old"), "a"))
    }

    @Test
    fun `直近操作は現在の選択が新しい一覧に残っていても直近へ移す`() {
        val pending = PendingItineraryNavigation("recent", "a", "g", "old")
        assertEquals("b", pendingItineraryTarget(pending, cache(listOf("a", "b")), "a"))
    }

    @Test
    fun `取得待ちの間に別の日付かグループへ変更したら古い操作を適用しない`() {
        val pending = PendingItineraryNavigation("next", "a", "g", "old")
        assertNull(pendingItineraryTarget(pending, cache(listOf("a", "b")), "b"))
        assertNull(pendingItineraryTarget(pending.copy(groupId = "other"), cache(listOf("a", "b")), "a"))
    }
}
