package com.example.trackgeek.widget

import android.content.Context

data class WidgetConfig(
    val showWatching: Boolean = true,
    val showReading: Boolean = true,
    val background: Boolean = true,
    val coversOnly: Boolean = false,
) {
    companion object {
        private const val PREFS = "trackgeek_widget"
        private const val KEY_WATCHING = "watching"
        private const val KEY_READING = "reading"
        private const val KEY_BACKGROUND = "background"
        private const val KEY_COVERS_ONLY = "coversOnly"

        fun load(context: Context, widgetId: Int): WidgetConfig {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            fun key(name: String) = "$widgetId.$name"
            return WidgetConfig(
                showWatching = prefs.getBoolean(key(KEY_WATCHING), true),
                showReading = prefs.getBoolean(key(KEY_READING), true),
                background = prefs.getBoolean(key(KEY_BACKGROUND), true),
                coversOnly = prefs.getBoolean(key(KEY_COVERS_ONLY), false),
            )
        }

        fun save(context: Context, widgetId: Int, config: WidgetConfig) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean("$widgetId.$KEY_WATCHING", config.showWatching)
                .putBoolean("$widgetId.$KEY_READING", config.showReading)
                .putBoolean("$widgetId.$KEY_BACKGROUND", config.background)
                .putBoolean("$widgetId.$KEY_COVERS_ONLY", config.coversOnly)
                .apply()
        }

        fun delete(context: Context, widgetId: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove("$widgetId.$KEY_WATCHING")
                .remove("$widgetId.$KEY_READING")
                .remove("$widgetId.$KEY_BACKGROUND")
                .remove("$widgetId.$KEY_COVERS_ONLY")
                .apply()
        }
    }
}
