package com.example.memora

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import java.util.ArrayDeque
import java.util.UUID
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.json.JSONObject

class MemoraWidgetActionWorker(
    private val context: Context,
    workerParams: WorkerParameters,
) : CoroutineWorker(context, workerParams), MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override suspend fun doWork(): Result {
        val action = inputData.getString(ACTION_KEY).orEmpty()
        val actionId = inputData.getString(ACTION_ID_KEY).orEmpty()
        val uri = inputData.getString(URI_KEY).orEmpty()

        val callbackCompleted = runCatching {
            ensureFlutterEngine()
            engine?.let {
                channel = MethodChannel(it.dartExecutor.binaryMessenger, CHANNEL_NAME)
                channel.setMethodCallHandler(this)
            }
            invokeDartCallback(listOf(HomeWidgetPlugin.getHandle(context), uri))
        }.getOrElse { error ->
            Log.e(TAG, "Failed to run widget action", error)
            false
        }

        val message = readToastMessage(context, actionId)
            ?: fallbackFailureMessage(action)
        clearActionResult(context, actionId)
        if (message.isNotBlank()) {
            showToast(context, message)
        }

        return if (callbackCompleted) Result.success() else Result.failure()
    }

    private suspend fun ensureFlutterEngine() {
        if (engine != null) {
            return
        }

        val callbackHandle = HomeWidgetPlugin.getDispatcherHandle(context)
        if (callbackHandle == 0L) {
            throw IllegalStateException(
                "No callbackHandle saved. Did you call HomeWidget.registerInteractivityCallback?",
            )
        }

        val callbackInfo = FlutterCallbackInformation
            .lookupCallbackInformation(callbackHandle)
            ?: throw IllegalStateException("Failed to lookup callback information")

        withContext(Dispatchers.Main) {
            engine = FlutterEngine(context)
            val callback = DartExecutor.DartCallback(
                context.assets,
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                callbackInfo,
            )
            engine?.dartExecutor?.executeDartCallback(callback)
        }
    }

    private suspend fun invokeDartCallback(args: List<Any>): Boolean {
        val completed = CompletableDeferred<Boolean>()
        synchronized(queueLock) {
            if (!serviceStarted) {
                queue.add(PendingInvocation(args, completed))
            } else {
                postInvocation(args, completed)
            }
        }
        return withTimeoutOrNull(CALLBACK_TIMEOUT_MILLIS) {
            completed.await()
        } == true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "HomeWidget.backgroundInitialized" -> {
                handleBackgroundInitialized()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleBackgroundInitialized() {
        synchronized(queueLock) {
            while (queue.isNotEmpty()) {
                val invocation = queue.remove()
                postInvocation(invocation.args, invocation.completed)
            }
            serviceStarted = true
        }
    }

    private fun postInvocation(
        args: List<Any>,
        completed: CompletableDeferred<Boolean>,
    ) {
        mainHandler.post {
            channel.invokeMethod(
                "",
                args,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        completed.complete(true)
                    }

                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?,
                    ) {
                        completed.complete(false)
                    }

                    override fun notImplemented() {
                        completed.complete(false)
                    }
                },
            )
        }
    }

    private data class PendingInvocation(
        val args: List<Any>,
        val completed: CompletableDeferred<Boolean>,
    )

    companion object {
        private const val TAG = "MemoraWidgetWorker"
        private const val ACTION_KEY = "action"
        private const val ACTION_ID_KEY = "action_id"
        private const val URI_KEY = "uri"
        private const val CHANNEL_NAME = "home_widget/background"
        private const val UNIQUE_WORK_NAME = "memora_widget_action"
        private const val CALLBACK_TIMEOUT_MILLIS = 60000L
        private const val ACTION_RESULT_KEY_PREFIX = "memora_widget_action_result_"

        @Volatile private var engine: FlutterEngine? = null
        private val queue = ArrayDeque<PendingInvocation>()
        private val queueLock = Any()
        private var serviceStarted = false
        private val mainHandler = Handler(Looper.getMainLooper())

        fun enqueue(context: Context, action: String) {
            val actionId = UUID.randomUUID().toString()
            val uri = Uri.parse("memoraWidget://$action?actionId=$actionId").toString()
            val data = Data.Builder()
                .putString(ACTION_KEY, action)
                .putString(ACTION_ID_KEY, actionId)
                .putString(URI_KEY, uri)
                .build()
            val workRequest = OneTimeWorkRequestBuilder<MemoraWidgetActionWorker>()
                .setInputData(data)
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                UNIQUE_WORK_NAME,
                ExistingWorkPolicy.APPEND,
                workRequest,
            )
        }

        private fun readToastMessage(context: Context, actionId: String): String? {
            if (actionId.isBlank()) {
                return null
            }
            val raw = HomeWidgetPlugin.getData(context)
                .getString("$ACTION_RESULT_KEY_PREFIX$actionId", null)
                ?: return null
            return runCatching {
                JSONObject(raw).optString("message")
            }.getOrNull()
        }

        private fun clearActionResult(context: Context, actionId: String) {
            if (actionId.isBlank()) {
                return
            }
            HomeWidgetPlugin.getData(context)
                .edit()
                .remove("$ACTION_RESULT_KEY_PREFIX$actionId")
                .apply()
        }

        private fun fallbackFailureMessage(action: String): String {
            return when (action) {
                "refresh" -> "更新に失敗しました"
                "previous", "next" -> "切り替えに失敗しました"
                else -> "操作に失敗しました"
            }
        }

        private fun showToast(context: Context, message: String) {
            mainHandler.post {
                Toast.makeText(
                    context.applicationContext,
                    message,
                    Toast.LENGTH_SHORT,
                ).show()
            }
        }
    }
}
