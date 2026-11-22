package com.example.memora

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.work.Configuration
import androidx.work.ExistingWorkPolicy
import androidx.work.ListenableWorker
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.WorkerFactory
import androidx.work.WorkerParameters
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import com.google.common.util.concurrent.ListenableFuture
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE, application = Application::class)
class AndroidWidgetBackgroundReceiverTest {
    private lateinit var context: Context
    private lateinit var manager: WorkManager
    private val received = mutableListOf<String?>()
    private var holdNext = false
    private var pending: ResultFuture? = null

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
        val factory = object : WorkerFactory() {
            override fun createWorker(
                appContext: Context,
                workerClassName: String,
                workerParameters: WorkerParameters,
            ): ListenableWorker? {
                if (workerClassName != HomeWidgetBackgroundWorker::class.java.name) return null
                return object : ListenableWorker(appContext, workerParameters) {
                    override fun startWork(): ListenableFuture<Result> {
                        received.add(inputData.getString("uri_data"))
                        return ResultFuture().also { future ->
                            if (holdNext) {
                                holdNext = false
                                pending = future
                            } else {
                                future.complete(Result.success())
                            }
                        }
                    }
                }
            }
        }
        val configuration = Configuration.Builder()
            .setExecutor(SynchronousExecutor())
            .setWorkerFactory(factory)
            .build()
        WorkManagerTestInitHelper.initializeTestWorkManager(context, configuration)
        manager = WorkManager.getInstance(context)
    }

    @After
    fun tearDown() {
        pending?.complete(ListenableWorker.Result.success())
        manager.cancelAllWork().result.get(10, TimeUnit.SECONDS)
        WorkManagerTestInitHelper.closeWorkDatabase()
    }

    @Test
    fun `失敗した更新列があっても新しい更新URIを実行する`() {
        val failed = OneTimeWorkRequestBuilder<FailedWorker>().build()
        manager.enqueueUniqueWork("home_widget_background", ExistingWorkPolicy.APPEND, failed)
            .result.get(10, TimeUnit.SECONDS)
        assertEquals(WorkInfo.State.FAILED, manager.getWorkInfoById(failed.id).get()!!.state)

        val uri = Uri.parse("memoraWidget://calendarRefresh?date=2026-12-01")
        AndroidWidgetBackgroundReceiver.enqueue(context, uri).result.get(10, TimeUnit.SECONDS)

        assertEquals(listOf(uri.toString()), received)
        assertEquals(WorkInfo.State.SUCCEEDED, manager.getWorkInfosForUniqueWork("home_widget_background").get().single().state)
    }

    @Test
    fun `実行中の更新を止めずに後続の更新を順番に実行する`() {
        val first = Uri.parse("memoraWidget://refresh")
        val next = Uri.parse("memoraWidget://itineraryrefresh?extend=true")
        holdNext = true
        AndroidWidgetBackgroundReceiver.enqueue(context, first).result.get(10, TimeUnit.SECONDS)
        AndroidWidgetBackgroundReceiver.enqueue(context, next).result.get(10, TimeUnit.SECONDS)
        assertEquals(listOf(first.toString()), received)
        assertEquals(setOf(WorkInfo.State.RUNNING, WorkInfo.State.BLOCKED), manager.getWorkInfosForUniqueWork("home_widget_background").get().map { it.state }.toSet())

        pending!!.complete(ListenableWorker.Result.success())

        assertEquals(listOf(first.toString(), next.toString()), received)
        assertEquals(setOf(WorkInfo.State.SUCCEEDED), manager.getWorkInfosForUniqueWork("home_widget_background").get().map { it.state }.toSet())
    }

    @Test
    fun `キャンセルされた更新列の後も次の更新を実行する`() {
        holdNext = true
        AndroidWidgetBackgroundReceiver.enqueue(context, Uri.parse("memoraWidget://refresh"))
            .result.get(10, TimeUnit.SECONDS)
        manager.cancelUniqueWork("home_widget_background").result.get(10, TimeUnit.SECONDS)
        val uri = Uri.parse("memoraWidget://calendarRefresh?date=2027-01-01")

        AndroidWidgetBackgroundReceiver.enqueue(context, uri).result.get(10, TimeUnit.SECONDS)

        assertEquals(uri.toString(), received.last())
        assertEquals(WorkInfo.State.SUCCEEDED, manager.getWorkInfosForUniqueWork("home_widget_background").get().single().state)
    }

    class FailedWorker(context: Context, parameters: WorkerParameters) : ListenableWorker(context, parameters) {
        override fun startWork(): ListenableFuture<Result> = ResultFuture().apply {
            complete(Result.failure())
        }
    }

    class ResultFuture : CompletableFuture<ListenableWorker.Result>(), ListenableFuture<ListenableWorker.Result> {
        override fun addListener(listener: Runnable, executor: Executor) {
            whenComplete { _, _ -> executor.execute(listener) }
        }
    }
}
