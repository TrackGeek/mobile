package com.example.trackgeek.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.example.trackgeek.R

class TrackingWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TrackingFactory(
            applicationContext,
            intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            ),
            intent.getStringExtra(EXTRA_SECTION) ?: TrackingApi.SECTION_WATCHING,
        )
    }

    companion object {
        const val EXTRA_SECTION = "trackgeek.section"
    }
}

private class TrackingFactory(
    private val context: Context,
    private val widgetId: Int,
    private val section: String,
) : RemoteViewsService.RemoteViewsFactory {

    private var items: List<TrackingApi.TrackingItem> = emptyList()
    private var coversOnly = false

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val config = WidgetConfig.load(context, widgetId)
        coversOnly = config.coversOnly
        when (val result = TrackingApi.fetch(context, section)) {
            is TrackingApi.Result.SignedOut -> {
                items = emptyList()
            }
            is TrackingApi.Result.Failure -> {
                items = emptyList()
            }
            is TrackingApi.Result.Ok -> {
                items = result.items
                val density = context.resources.displayMetrics.density
                for (item in items) {
                    val url = item.imageUrl ?: continue
                    item.cover = TrackingApi.downloadCover(url, 10f, density)
                }
            }
        }
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_tracking_item)
        val item = items.getOrNull(position) ?: return views
        if (item.cover != null) {
            views.setImageViewBitmap(R.id.item_cover, item.cover)
        } else {
            views.setImageViewResource(R.id.item_cover, R.drawable.widget_cover_placeholder)
        }
        if (coversOnly) {
            views.setViewVisibility(R.id.item_scrim, View.GONE)
            views.setViewVisibility(R.id.item_texts, View.GONE)
        } else {
            views.setViewVisibility(R.id.item_scrim, View.VISIBLE)
            views.setViewVisibility(R.id.item_texts, View.VISIBLE)
            views.setTextViewText(R.id.item_title, item.title)
            val label = item.progressLabel
            if (label.isNullOrEmpty()) {
                views.setViewVisibility(R.id.item_progress, View.GONE)
            } else {
                views.setViewVisibility(R.id.item_progress, View.VISIBLE)
                views.setTextViewText(R.id.item_progress, label)
            }
        }
        views.setOnClickFillInIntent(
            R.id.item_container,
            Intent().putExtra(TrackingWidgetProvider.EXTRA_OPEN_APP, true),
        )
        return views
    }

    override fun getLoadingView(): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_tracking_item)

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    override fun getCount(): Int = items.size

    override fun onDestroy() {}
}
