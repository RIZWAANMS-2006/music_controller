package com.example.Rusic

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MusicWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val title = widgetData.getString("song_title", "No Song")

            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                setTextViewText(R.id.widget_song_title, title)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}