package com.example.memora

import android.content.Context
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.CircularBounds
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.PlacesClient
import com.google.android.libraries.places.api.net.SearchByTextRequest
import com.google.android.libraries.places.api.net.SearchNearbyRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class PlacesMethodChannelHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private var placesClient: PlacesClient? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "searchByText" -> searchByText(call, result)
            "searchNearby" -> searchNearby(call, result)
            else -> result.notImplemented()
        }
    }

    private fun searchByText(call: MethodCall, result: MethodChannel.Result) {
        val query = call.argument<String>("query").orEmpty()
        val client = getPlacesClient(result) ?: return
        val request = SearchByTextRequest
            .builder(query, LOCATION_SEARCH_FIELDS)
            .setMaxResultCount(20)
            .build()

        client.searchByText(request)
            .addOnSuccessListener { response ->
                result.success(response.places.map(::toLocationCandidate))
            }
            .addOnFailureListener { exception ->
                result.error("PLACES_TEXT_SEARCH_ERROR", exception.message, null)
            }
    }

    private fun searchNearby(call: MethodCall, result: MethodChannel.Result) {
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")
        val radiusMeters = call.argument<Double>("radiusMeters")
        val maxResultCount = call.argument<Int>("maxResultCount")

        if (latitude == null || longitude == null || radiusMeters == null || maxResultCount == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Nearby Search requires latitude, longitude, radiusMeters, and maxResultCount.",
                null,
            )
            return
        }

        val client = getPlacesClient(result) ?: return
        val circle = CircularBounds.newInstance(LatLng(latitude, longitude), radiusMeters)
        val request = SearchNearbyRequest
            .builder(circle, NEARBY_SEARCH_FIELDS)
            .setMaxResultCount(maxResultCount)
            .setRankPreference(SearchNearbyRequest.RankPreference.POPULARITY)
            .build()

        client.searchNearby(request)
            .addOnSuccessListener { response ->
                result.success(response.places.firstOrNull()?.displayName)
            }
            .addOnFailureListener { exception ->
                result.error("PLACES_NEARBY_SEARCH_ERROR", exception.message, null)
            }
    }

    private fun getPlacesClient(result: MethodChannel.Result): PlacesClient? {
        val apiKey = BuildConfig.MAPS_API_KEY
        if (apiKey.isBlank()) {
            result.error(
                "MAPS_API_KEY_MISSING",
                "MAPS_API_KEY is not set in local.properties.",
                null,
            )
            return null
        }

        if (!Places.isInitialized()) {
            Places.initializeWithNewPlacesApiEnabled(context, apiKey, Locale.JAPAN)
        }

        return placesClient ?: Places.createClient(context).also {
            placesClient = it
        }
    }

    private fun toLocationCandidate(place: Place): Map<String, Any> {
        val location = place.location
        return mapOf(
            "name" to (place.displayName ?: ""),
            "address" to (place.formattedAddress ?: ""),
            "latitude" to (location?.latitude ?: 0.0),
            "longitude" to (location?.longitude ?: 0.0),
        )
    }

    companion object {
        const val CHANNEL = "memora/places"

        private val LOCATION_SEARCH_FIELDS = listOf(
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION,
        )
        private val NEARBY_SEARCH_FIELDS = listOf(Place.Field.DISPLAY_NAME)
    }
}
