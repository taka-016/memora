package com.example.memora

internal data class PendingItineraryNavigation(
    val action: String,
    val sourceId: String,
    val groupId: String,
    val generation: String,
)

internal fun itineraryAdjacentId(ids: List<String>, selectedId: String?, previous: Boolean): String? {
    val index = ids.indexOf(selectedId)
    if (index < 0) return null
    return ids.getOrNull(index + if (previous) -1 else 1)
}

internal fun pendingItineraryTarget(
    pending: PendingItineraryNavigation,
    cache: ItineraryWidgetCache,
    currentId: String?,
): String? {
    if (pending.groupId != cache.groupId || pending.sourceId != currentId ||
        pending.generation == cache.generation) return null
    return when (pending.action) {
        "previous" -> itineraryAdjacentId(cache.dateIds, pending.sourceId, true)
        "next" -> itineraryAdjacentId(cache.dateIds, pending.sourceId, false)
        "recent" -> cache.recentId?.takeIf { it in cache.dateIds }
        else -> null
    }
}
