package com.onaria.buddhist

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tts: TextToSpeech? = null
    private var speechEpoch = 0
    private var blocked = false
    private var permissionResult: MethodChannel.Result? = null
    private var reminderMinutes = 1

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.onaria.buddhist/offline").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "safetyStop" -> {
                        blocked = true
                        stopSpeech()
                        permissionResult?.success(false); permissionResult = null
                        ReminderReceiver.cancel(this)
                        result.success(true)
                    }
                    "stopSpeech" -> { stopSpeech(); result.success(true) }
                    "cancelReminder" -> { permissionResult?.success(false); permissionResult = null; ReminderReceiver.cancel(this); result.success(true) }
                    "share", "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        if (blocked || !text.startsWith("TEST_DATA_ONLY") || text.length > 6000) {
                            result.success(false)
                        } else if (call.method == "share") {
                            startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"; putExtra(Intent.EXTRA_TEXT, text)
                            }, "테스트 마음카드 공유"))
                            result.success(true)
                        } else speak(text, result)
                    }
                    "reminder" -> {
                        val minutes = call.argument<Int>("minutes") ?: 0
                        if (blocked || minutes !in listOf(1, 1440) || permissionResult != null) {
                            result.success(false)
                        } else if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            permissionResult = result; reminderMinutes = minutes
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 61)
                        } else result.success(ReminderReceiver.schedule(this, minutes))
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("UNAVAILABLE", "기기 기능을 사용할 수 없습니다.", null) }
        }
    }
    private fun stopSpeech() {
        speechEpoch++
        tts?.stop(); tts?.shutdown(); tts = null
    }
    private fun speak(text: String, result: MethodChannel.Result) {
        stopSpeech()
        val epoch = speechEpoch
        tts = TextToSpeech(this) { status ->
            try {
            val current = tts
            if (blocked || epoch != speechEpoch || status != TextToSpeech.SUCCESS || current == null) {
                result.success(false)
            } else {
                val voice = current.voices?.firstOrNull { it.locale.language == "ko" && !it.isNetworkConnectionRequired }
                if (voice == null) { stopSpeech(); result.success(false) }
                else {
                    if (current.setVoice(voice) != TextToSpeech.SUCCESS) {
                        stopSpeech(); result.success(false); return@TextToSpeech
                    }
                    result.success(current.speak(text, TextToSpeech.QUEUE_FLUSH, null, "buddhist-mock") == TextToSpeech.SUCCESS)
                }
            }
            } catch (_: Exception) { stopSpeech(); result.success(false) }
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, results)
        if (requestCode == 61) {
            val pending = permissionResult; permissionResult = null
            if (pending != null) {
                try { pending.success(!blocked && results.firstOrNull() == PackageManager.PERMISSION_GRANTED && ReminderReceiver.schedule(this, reminderMinutes)) }
                catch (_: Exception) { pending.success(false) }
            }
        }
    }
    override fun onPause() { stopSpeech(); super.onPause() }
    override fun onDestroy() {
        stopSpeech()
        permissionResult?.success(false); permissionResult = null
        super.onDestroy()
    }
}
