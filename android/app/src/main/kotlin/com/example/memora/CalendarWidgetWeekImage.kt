package com.example.memora

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.TypedValue
import java.time.LocalDate
import kotlin.math.roundToInt

internal object CalendarWidgetWeekImage {
    fun render(
        context: Context,
        days: List<CalendarWidgetDay>,
        month: LocalDate,
        widthDp: Int,
        heightDp: Float,
        compact: Boolean,
        maxLines: Int,
        appearance: WidgetAppearance,
    ): Bitmap {
        val metrics = context.resources.displayMetrics
        fun dp(value: Float) = value * metrics.density
        fun sp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, metrics)
        val width = dp(widthDp.toFloat()).roundToInt().coerceAtLeast(1)
        val height = dp(heightDp).roundToInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val headerHeight = dp(if (compact) 14f else 19f)
        val laneHeight = dp(if (compact) 8f else 12f)
        val lines = minOf(maxLines, ((height - headerHeight - dp(1f)) / laneHeight).toInt().coerceAtLeast(0))
        if (lines == 0) return bitmap
        val layout = CalendarWidgetWeekLayout(days, month, lines)
        val columnWidth = width / 7f
        val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = sp(if (compact) 8f else 9f)
        }
        val more = Paint(Paint.ANTI_ALIAS_FLAG).apply { textSize = sp(7f) }
        fun remainingWidth(column: Int): Float = if (layout.remainingCounts[column] > 0) {
            more.measureText("+${layout.remainingCounts[column]}") + dp(2f)
        } else 0f

        layout.entries.forEach { entry ->
            val left = columnWidth * entry.startColumn + dp(2f)
            val right = columnWidth * (entry.endColumn + 1) - dp(2f)
            val top = headerHeight + entry.lane * laneHeight + dp(.5f)
            val bottom = headerHeight + (entry.lane + 1) * laneHeight
            if (right <= left) return@forEach
            val rect = RectF(left, top, right, bottom)
            if (entry.filled) {
                fill.color = entry.event.color
                canvas.drawRoundRect(rect, dp(2f), dp(2f), fill)
            } else {
                fill.color = entry.event.color
                canvas.drawRect(left, top, left + dp(3f), bottom, fill)
            }
            val textLeft = left + dp(if (entry.filled) 2f else 5f)
            var textRight = right - dp(if (entry.filled) 2f else 0f)
            if (entry.startColumn == entry.endColumn && entry.lane == lines - 1) {
                textRight -= remainingWidth(entry.startColumn)
            }
            if (textRight <= textLeft) return@forEach
            text.color = if (entry.filled) entry.event.textColor else appearance.text
            val title = entry.event.title.replace('\n', ' ').replace('\r', ' ')
            val fits = text.measureText(title) <= textRight - textLeft
            text.textAlign = if (entry.filled && fits) Paint.Align.CENTER else Paint.Align.LEFT
            val x = if (entry.filled && fits) (textLeft + textRight) / 2 else textLeft
            val baseline = rect.centerY() - (text.fontMetrics.ascent + text.fontMetrics.descent) / 2
            val saved = canvas.save()
            canvas.clipRect(textLeft, top, textRight, bottom)
            canvas.drawText(title, x, baseline, text)
            canvas.restoreToCount(saved)
        }
        layout.remainingCounts.forEachIndexed { column, remaining ->
            if (remaining <= 0) return@forEachIndexed
            val owner = layout.entries.firstOrNull {
                it.lane == lines - 1 && column in it.startColumn..it.endColumn
            }
            val right = columnWidth * (column + 1) - dp(2f)
            val top = headerHeight + (lines - 1) * laneHeight + dp(.5f)
            val bottom = headerHeight + lines * laneHeight
            fill.color = if (owner?.filled == true) owner.event.color else Color.TRANSPARENT
            if (fill.color != Color.TRANSPARENT) {
                canvas.drawRect(right - remainingWidth(column), top, right, bottom, fill)
            }
            more.color = if (owner?.filled == true) owner.event.textColor else appearance.text
            more.textAlign = Paint.Align.RIGHT
            val baseline = (top + bottom) / 2 - (more.fontMetrics.ascent + more.fontMetrics.descent) / 2
            val saved = canvas.save()
            canvas.clipRect(columnWidth * column, top, right, bottom)
            canvas.drawText("+$remaining", right, baseline, more)
            canvas.restoreToCount(saved)
        }
        return bitmap
    }
}
