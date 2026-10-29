package com.example.trackgeek.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.example.trackgeek.MainActivity
import com.example.trackgeek.R

class TrackingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id)
        appWidgetManager.notifyAppWidgetViewDataChanged(
            appWidgetIds,
            R.id.grid_watching,
        )
        appWidgetManager.notifyAppWidgetViewDataChanged(
            appWidgetIds,
            R.id.grid_reading,
        )
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (id in appWidgetIds) WidgetConfig.delete(context, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) refreshAll(context)
    }

    companion object {
        const val ACTION_REFRESH = "com.example.trackgeek.widget.REFRESH"
        const val EXTRA_OPEN_APP = "trackgeek.openApp"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TrackingWidgetProvider::class.java),
            )
            for (id in ids) updateWidget(context, manager, id)
            manager.notifyAppWidgetViewDataChanged(ids, R.id.grid_watching)
            manager.notifyAppWidgetViewDataChanged(ids, R.id.grid_reading)
        }

        fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val config = WidgetConfig.load(context, widgetId)
            val views = RemoteViews(context.packageName, R.layout.widget_tracking)

            views.setInt(
                R.id.widget_container,
                "setBackgroundResource",
                if (config.background) R.drawable.widget_background
                else android.R.color.transparent,
            )

            val showWatching = config.showWatching
            val showReading = config.showReading
            val headersVisible = !config.coversOnly

            views.setViewVisibility(
                R.id.header_watching,
                visible(showWatching && headersVisible),
            )
            views.setViewVisibility(
                R.id.frame_watching,
                visible(showWatching),
            )
            views.setViewVisibility(
                R.id.header_reading,
                visible(showReading && headersVisible),
            )
            views.setViewVisibility(
                R.id.frame_reading,
                visible(showReading),
            )

            views.setRemoteAdapter(
                R.id.grid_watching,
                sectionIntent(context, widgetId, TrackingApi.SECTION_WATCHING),
            )
            views.setRemoteAdapter(
                R.id.grid_reading,
                sectionIntent(context, widgetId, TrackingApi.SECTION_READING),
            )
            views.setEmptyView(R.id.grid_watching, R.id.empty_watching)
            views.setEmptyView(R.id.grid_reading, R.id.empty_reading)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val launchPending = PendingIntent.getActivity(
                context,
                widgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE,
            )
            views.setPendingIntentTemplate(R.id.grid_watching, launchPending)
            views.setPendingIntentTemplate(R.id.grid_reading, launchPending)
            views.setOnClickPendingIntent(R.id.widget_logo, launchPending)

            val refreshIntent = Intent(context, TrackingWidgetProvider::class.java)
                .setAction(ACTION_REFRESH)
            val refreshPending = PendingIntent.getBroadcast(
                context,
                widgetId,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshPending)

            manager.updateAppWidget(widgetId, views)
        }

        private fun sectionIntent(
            context: Context,
            widgetId: Int,
            section: String,
        ): Intent = Intent(context, TrackingWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(TrackingWidgetService.EXTRA_SECTION, section)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }

        private fun visible(show: Boolean): Int =
            if (show) View.VISIBLE else View.GONE
    }
}
