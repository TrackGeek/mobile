package com.example.trackgeek.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.Switch
import com.example.trackgeek.R

class TrackingWidgetConfigActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    private lateinit var preview: View
    private lateinit var previewTexts: List<View>
    private lateinit var watchingCheck: CheckBox
    private lateinit var readingCheck: CheckBox
    private lateinit var backgroundSwitch: Switch
    private lateinit var coversOnlyCheck: CheckBox

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.widget_config)

        preview = findViewById(R.id.preview_container)
        previewTexts = listOf(
            findViewById(R.id.preview_text_1),
            findViewById(R.id.preview_text_2),
            findViewById(R.id.preview_text_3),
        )
        watchingCheck = findViewById(R.id.check_watching)
        readingCheck = findViewById(R.id.check_reading)
        backgroundSwitch = findViewById(R.id.switch_background)
        coversOnlyCheck = findViewById(R.id.check_covers_only)

        backgroundSwitch.setOnCheckedChangeListener { _, checked ->
            preview.setBackgroundResource(
                if (checked) R.drawable.widget_background
                else android.R.color.transparent,
            )
        }
        coversOnlyCheck.setOnCheckedChangeListener { _, checked ->
            val visibility = if (checked) View.GONE else View.VISIBLE
            previewTexts.forEach { it.visibility = visibility }
            findViewById<View>(R.id.preview_header).visibility = visibility
        }

        findViewById<Button>(R.id.button_add).setOnClickListener {
            val config = WidgetConfig(
                showWatching = watchingCheck.isChecked,
                showReading = readingCheck.isChecked,
                background = backgroundSwitch.isChecked,
                coversOnly = coversOnlyCheck.isChecked,
            )
            WidgetConfig.save(this, widgetId, config)
            val manager = AppWidgetManager.getInstance(this)
            TrackingWidgetProvider.updateWidget(this, manager, widgetId)
            manager.notifyAppWidgetViewDataChanged(
                intArrayOf(widgetId),
                R.id.grid_watching,
            )
            manager.notifyAppWidgetViewDataChanged(
                intArrayOf(widgetId),
                R.id.grid_reading,
            )
            setResult(
                RESULT_OK,
                Intent().putExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    widgetId,
                ),
            )
            finish()
        }
    }
}
