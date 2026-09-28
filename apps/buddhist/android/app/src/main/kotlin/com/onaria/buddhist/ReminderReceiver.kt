package com.onaria.buddhist

import android.app.*
import android.content.*
import android.os.Build

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("buddhist_reminder", Context.MODE_PRIVATE)
        val scheduled = prefs.getLong("at", 0)
        if (scheduled == 0L || intent.getLongExtra("at", -1) != scheduled) return
        prefs.edit().remove("at").apply()
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel("buddhist_rest", "작은 쉼", NotificationManager.IMPORTANCE_DEFAULT))
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, "buddhist_rest") else Notification.Builder(context)
        try {
            manager.notify(61, builder.setSmallIcon(android.R.drawable.ic_popup_reminder)
                .setContentTitle("작은 쉼")
                .setContentText("편한 때 잠시 쉬어 가세요.")
                .setVisibility(Notification.VISIBILITY_PRIVATE)
                .setContentIntent(open).setAutoCancel(true).build())
        } catch (_: SecurityException) { /* permission may have been revoked */ }
    }
    companion object {
        fun cancel(context: Context) {
            context.getSharedPreferences("buddhist_reminder", Context.MODE_PRIVATE).edit().remove("at").apply()
            val pending = PendingIntent.getBroadcast(context, 61, Intent(context, ReminderReceiver::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            context.getSystemService(AlarmManager::class.java).cancel(pending)
            context.getSystemService(NotificationManager::class.java).cancel(61)
        }
        fun schedule(context: Context, minutes: Int): Boolean {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (!manager.areNotificationsEnabled()) return false
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel("buddhist_rest", "작은 쉼", NotificationManager.IMPORTANCE_DEFAULT))
                if (manager.getNotificationChannel("buddhist_rest").importance == NotificationManager.IMPORTANCE_NONE) return false
            }
            val at = System.currentTimeMillis() + minutes * 60_000L
            val pending = PendingIntent.getBroadcast(context, 61,
                Intent(context, ReminderReceiver::class.java).putExtra("at", at), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            context.getSharedPreferences("buddhist_reminder", Context.MODE_PRIVATE).edit().putLong("at", at).apply()
            return true
        }
    }
}
