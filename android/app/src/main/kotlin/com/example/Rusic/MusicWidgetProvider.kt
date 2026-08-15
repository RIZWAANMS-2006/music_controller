package com.example.Rusic

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MusicWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                // Open App on title click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.tv_title, pendingIntent)

                // Get data from SharedPreferences sent by Dart
                val title = widgetData.getString("title", "Not Playing")
                val isPlaying = widgetData.getBoolean("isPlaying", false)
                val progress = widgetData.getInt("progress", 0)
                val loopMode = widgetData.getString("loopMode", "off") // off, all, one
                val shuffleMode = widgetData.getBoolean("shuffleMode", false)
                
                setTextViewText(R.id.tv_title, title)
                setProgressBar(R.id.pb_progress, 1000, progress, false)
                
                setImageViewResource(R.id.btn_play_pause, if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play)
                
                setInt(R.id.btn_shuffle, "setImageAlpha", if (shuffleMode) 255 else 100)
                setInt(R.id.btn_loop, "setImageAlpha", if (loopMode != "off") 255 else 100)

                // Intents for background callbacks to Dart
                val playPauseIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("rusic://playpause"))
                setOnClickPendingIntent(R.id.btn_play_pause, playPauseIntent)
                
                val nextIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("rusic://next"))
                setOnClickPendingIntent(R.id.btn_next, nextIntent)
                
                val prevIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("rusic://prev"))
                setOnClickPendingIntent(R.id.btn_prev, prevIntent)
                
                val loopIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("rusic://loop"))
                setOnClickPendingIntent(R.id.btn_loop, loopIntent)
                
                val shuffleIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("rusic://shuffle"))
                setOnClickPendingIntent(R.id.btn_shuffle, shuffleIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
