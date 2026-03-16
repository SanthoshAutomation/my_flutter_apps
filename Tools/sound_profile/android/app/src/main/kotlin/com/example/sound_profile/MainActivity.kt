package com.example.sound_profile

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.example.sound_profile/audio"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "applyProfile" -> {
                        try {
                            // ringerMode: 0 = silent, 1 = vibrate, 2 = normal
                            val ringerMode = call.argument<Int>("ringerMode") ?: 2

                            if (ringerMode == 0 && !hasDndAccess()) {
                                result.error(
                                    "PERMISSION_DENIED",
                                    "Do Not Disturb access required for Silent mode",
                                    null
                                )
                                return@setMethodCallHandler
                            }

                            audio.ringerMode = ringerMode

                            // Only set ring/notification volumes in NORMAL mode;
                            // VIBRATE/SILENT ringer mode already handles those streams.
                            if (ringerMode == 2) {
                                setVol(audio, AudioManager.STREAM_RING,
                                    call.argument("ringtoneVolume") ?: 70)
                                setVol(audio, AudioManager.STREAM_NOTIFICATION,
                                    call.argument("notificationVolume") ?: 70)
                            }
                            setVol(audio, AudioManager.STREAM_MUSIC,
                                call.argument("mediaVolume") ?: 50)
                            setVol(audio, AudioManager.STREAM_ALARM,
                                call.argument("alarmVolume") ?: 70)

                            // ── Vibration & haptics (Settings.System.VIBRATE_ON) ──
                            // This is the global "Use vibration & haptics" toggle that
                            // Motorola (and other OEMs) expose under Sound & Vibration.
                            // Without flipping this, RINGER_MODE_VIBRATE has no effect
                            // on devices where the user previously turned it off.
                            val hapticEnabled = call.argument<Boolean>("hapticEnabled")
                                ?: (ringerMode == 1) // default: on for vibrate mode
                            setVibrateOn(hapticEnabled)

                            result.success(true)
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", e.message, null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "getCurrentState" -> {
                        try {
                            result.success(
                                mapOf(
                                    "ringerMode" to audio.ringerMode,
                                    "ringtoneVolume" to getVol(audio, AudioManager.STREAM_RING),
                                    "mediaVolume" to getVol(audio, AudioManager.STREAM_MUSIC),
                                    "notificationVolume" to getVol(audio, AudioManager.STREAM_NOTIFICATION),
                                    "alarmVolume" to getVol(audio, AudioManager.STREAM_ALARM),
                                    "hasDndPermission" to hasDndAccess(),
                                    "hasWriteSettings" to Settings.System.canWrite(this),
                                    "vibrateOn" to (Settings.System.getInt(
                                        contentResolver, Settings.System.VIBRATE_ON, 1) == 1),
                                )
                            )
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "hasDndPermission" -> result.success(hasDndAccess())

                    "requestDndPermission" -> {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }

                    "requestWriteSettingsPermission" -> {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        )
                        result.success(null)
                    }

                    // Called after every profile save so the Quick Settings Tile
                    // can read up-to-date profiles even when the app is closed.
                    "saveProfilesToNative" -> {
                        val json = call.argument<String>("profilesJson") ?: "[]"
                        val idx = call.argument<Int>("activeIndex") ?: 0
                        getSharedPreferences("sound_profile_prefs", Context.MODE_PRIVATE)
                            .edit()
                            .putString("profiles", json)
                            .putInt("activeIndex", idx)
                            .apply()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Write Settings.System.VIBRATE_ON — the "Use vibration & haptics" master switch.
     * On Motorola Android 15 this controls all vibration including RINGER_MODE_VIBRATE.
     * Requires the WRITE_SETTINGS special permission granted via ACTION_MANAGE_WRITE_SETTINGS.
     */
    private fun setVibrateOn(enabled: Boolean) {
        if (!Settings.System.canWrite(this)) return
        Settings.System.putInt(
            contentResolver,
            Settings.System.VIBRATE_ON,
            if (enabled) 1 else 0
        )
    }

    private fun hasDndAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                as android.app.NotificationManager
        return nm.isNotificationPolicyAccessGranted
    }

    /** Convert a percentage (0–100) to the stream's actual volume scale and set it. */
    private fun setVol(audio: AudioManager, stream: Int, pct: Int) {
        val max = audio.getStreamMaxVolume(stream)
        audio.setStreamVolume(stream, (pct * max / 100).coerceIn(0, max), 0)
    }

    /** Return the current volume of a stream as a percentage (0–100). */
    private fun getVol(audio: AudioManager, stream: Int): Int {
        val max = audio.getStreamMaxVolume(stream)
        return if (max > 0) audio.getStreamVolume(stream) * 100 / max else 0
    }
}
