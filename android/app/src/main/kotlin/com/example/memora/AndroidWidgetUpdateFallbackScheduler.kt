package com.example.memora

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

object AndroidWidgetUpdateFallbackScheduler {
    fun schedule(context: Context) {
        val intervalMillis = TimeUnit.MINUTES.toMillis(
            FALLBACK_CHECK_INTERVAL_MINUTES,
        )
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val intent = Intent(
            context,
            AndroidWidgetUpdateFallbackReceiver::class.java,
        ).setAction(AndroidWidgetUpdateFallbackReceiver.ACTION_CHECK)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            FALLBACK_CHECK_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + intervalMillis,
            intervalMillis,
            pendingIntent,
        )
    }

    fun recoverIfOverdue(context: Context) {
        val preferences = homeWidgetPreferences(context)
        val targetGroupId = preferences
            .getString(TARGET_GROUP_ID_KEY, null)
            .orEmpty()
        if (targetGroupId.isEmpty()) {
            return
        }

        val updateIntervalMinutes = flutterPreferences(context)
            .getLong(UPDATE_INTERVAL_MINUTES_KEY, DEFAULT_UPDATE_INTERVAL_MINUTES)
            .coerceAtLeast(MINIMUM_WORK_INTERVAL_MINUTES)
        val lastUpdatedAt = loadLastUpdatedAt(context)
        val overdueThresholdMillis = TimeUnit.MINUTES.toMillis(
            updateIntervalMinutes + FALLBACK_GRACE_MINUTES,
        )
        if (lastUpdatedAt != null &&
            System.currentTimeMillis() - lastUpdatedAt.time < overdueThresholdMillis
        ) {
            return
        }

        val now = System.currentTimeMillis()
        val lastRecoveryEnqueuedAt = preferences.getLong(
            FALLBACK_RECOVERY_ENQUEUED_AT_KEY,
            0L,
        )
        val recoveryCooldownMillis = TimeUnit.MINUTES.toMillis(
            FALLBACK_RECOVERY_COOLDOWN_MINUTES,
        )
        if (now - lastRecoveryEnqueuedAt < recoveryCooldownMillis) {
            return
        }
        preferences.edit()
            .putLong(FALLBACK_RECOVERY_ENQUEUED_AT_KEY, now)
            .apply()

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        val inputData = Data.Builder()
            .putString(BackgroundWorker.DART_TASK_KEY, PERIODIC_UPDATE_TASK_NAME)
            .build()
        val periodicRequest = PeriodicWorkRequestBuilder<BackgroundWorker>(
            updateIntervalMinutes,
            TimeUnit.MINUTES,
        )
            .setConstraints(constraints)
            .setInputData(inputData)
            .setInitialDelay(updateIntervalMinutes, TimeUnit.MINUTES)
            .build()
        val immediateRequest = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setConstraints(constraints)
            .setInputData(inputData)
            .build()
        WorkManager.getInstance(context.applicationContext).apply {
            enqueueUniquePeriodicWork(
                PERIODIC_UPDATE_UNIQUE_NAME,
                ExistingPeriodicWorkPolicy.CANCEL_AND_REENQUEUE,
                periodicRequest,
            )
            enqueueUniqueWork(
                FALLBACK_UPDATE_UNIQUE_NAME,
                ExistingWorkPolicy.REPLACE,
                immediateRequest,
            )
        }
    }

    private fun loadLastUpdatedAt(context: Context): Date? {
        val value = homeWidgetPreferences(context)
            .getString(LAST_UPDATED_AT_KEY, null)
            .orEmpty()
        if (value.isEmpty()) {
            return null
        }
        return runCatching {
            SimpleDateFormat(LAST_UPDATED_AT_FORMAT, Locale.US).parse(value)
        }.getOrNull()
    }

    private fun homeWidgetPreferences(context: Context) =
        context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)

    private fun flutterPreferences(context: Context) =
        context.getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)

    private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
    private const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
    private const val TARGET_GROUP_ID_KEY = "memora_widget_target_group_id"
    private const val LAST_UPDATED_AT_KEY = "memora_widget_last_updated_at"
    private const val FALLBACK_RECOVERY_ENQUEUED_AT_KEY =
        "memora_widget_fallback_recovery_enqueued_at"
    private const val UPDATE_INTERVAL_MINUTES_KEY =
        "flutter.android_widget_update_interval_minutes"
    private const val PERIODIC_UPDATE_UNIQUE_NAME =
        "memora_android_widget_periodic_update"
    private const val PERIODIC_UPDATE_TASK_NAME =
        "memora_android_widget_periodic_update_task"
    private const val FALLBACK_UPDATE_UNIQUE_NAME =
        "memora_android_widget_fallback_update"
    private const val LAST_UPDATED_AT_FORMAT = "yyyy-MM-dd'T'HH:mm:ss"
    private const val DEFAULT_UPDATE_INTERVAL_MINUTES = 24L * 60L
    private const val MINIMUM_WORK_INTERVAL_MINUTES = 15L
    private const val FALLBACK_GRACE_MINUTES = 30L
    private const val FALLBACK_RECOVERY_COOLDOWN_MINUTES = 30L
    private const val FALLBACK_CHECK_INTERVAL_MINUTES = 30L
    private const val FALLBACK_CHECK_REQUEST_CODE = 2106
}
