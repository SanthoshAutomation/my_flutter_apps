package com.example.sound_profile

import android.content.Context
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import org.json.JSONArray

/**
 * Quick Settings tile that cycles through the user's saved sound profiles.
 *
 * Profiles are stored in the "sound_profile_prefs" SharedPreferences file
 * by MainActivity whenever the Flutter app saves changes, so this service
 * can operate even when the Flutter app is not running.
 *
 * Requires Android 7.0+ (API 24).
 */
@RequiresApi(Build.VERSION_CODES.N)
class SoundProfileTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()
        cycleProfile()
        updateTile()
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun prefs() =
        getSharedPreferences("sound_profile_prefs", Context.MODE_PRIVATE)

    private fun cycleProfile() {
        val profiles = loadProfiles()
        if (profiles.isEmpty()) return
        val next = (prefs().getInt("activeIndex", 0) + 1) % profiles.size
        applyProfile(profiles[next])
        prefs().edit().putInt("activeIndex", next).apply()
    }

    private fun applyProfile(profile: Map<String, Any>) {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            val ringerMode = profile["ringerMode"] as? Int ?: 2
            audio.ringerMode = ringerMode

            fun setVol(stream: Int, pct: Int) {
                val max = audio.getStreamMaxVolume(stream)
                audio.setStreamVolume(stream, (pct * max / 100).coerceIn(0, max), 0)
            }

            if (ringerMode == 2) {
                setVol(AudioManager.STREAM_RING,
                    profile["ringtoneVolume"] as? Int ?: 70)
                setVol(AudioManager.STREAM_NOTIFICATION,
                    profile["notificationVolume"] as? Int ?: 70)
            }
            setVol(AudioManager.STREAM_MUSIC, profile["mediaVolume"] as? Int ?: 50)
            setVol(AudioManager.STREAM_ALARM, profile["alarmVolume"] as? Int ?: 70)

            // Flip the global "Use vibration & haptics" toggle (VIBRATE_ON).
            // This is the setting the user previously had to toggle manually.
            val hapticEnabled = profile["hapticEnabled"] as? Boolean ?: (ringerMode == 1)
            if (Settings.System.canWrite(this)) {
                Settings.System.putInt(
                    contentResolver,
                    Settings.System.VIBRATE_ON,
                    if (hapticEnabled) 1 else 0
                )
            }
        } catch (_: Exception) {
            // Silently ignore if DND or write-settings permission is missing
        }
    }

    private fun loadProfiles(): List<Map<String, Any>> {
        val json = prefs().getString("profiles", null) ?: return defaultProfiles()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                mapOf(
                    "name" to o.getString("name"),
                    "ringerMode" to o.getInt("ringerMode"),
                    "ringtoneVolume" to o.getInt("ringtoneVolume"),
                    "mediaVolume" to o.getInt("mediaVolume"),
                    "notificationVolume" to o.getInt("notificationVolume"),
                    "alarmVolume" to o.getInt("alarmVolume"),
                    "hapticEnabled" to o.optBoolean("hapticEnabled", o.getInt("ringerMode") == 1),
                )
            }
        } catch (_: Exception) {
            defaultProfiles()
        }
    }

    private fun defaultProfiles(): List<Map<String, Any>> = listOf(
        mapOf("name" to "Normal", "ringerMode" to 2,
            "ringtoneVolume" to 70, "mediaVolume" to 50,
            "notificationVolume" to 70, "alarmVolume" to 70),
        mapOf("name" to "Office", "ringerMode" to 1,
            "ringtoneVolume" to 0, "mediaVolume" to 0,
            "notificationVolume" to 0, "alarmVolume" to 70),
        mapOf("name" to "Silent", "ringerMode" to 0,
            "ringtoneVolume" to 0, "mediaVolume" to 0,
            "notificationVolume" to 0, "alarmVolume" to 70),
    )

    private fun updateTile() {
        val tile = qsTile ?: return
        val profiles = loadProfiles()
        val idx = prefs().getInt("activeIndex", 0)
            .coerceIn(0, (profiles.size - 1).coerceAtLeast(0))

        if (profiles.isEmpty()) {
            tile.label = "Sound Profile"
            tile.state = Tile.STATE_INACTIVE
            tile.updateTile()
            return
        }

        val current = profiles[idx]
        val ringerMode = current["ringerMode"] as? Int ?: 2

        tile.label = current["name"] as? String ?: "Sound Profile"
        tile.state = Tile.STATE_ACTIVE
        tile.icon = Icon.createWithResource(
            this,
            when (ringerMode) {
                0 -> R.drawable.ic_tile_silent
                1 -> R.drawable.ic_tile_vibrate
                else -> R.drawable.ic_tile_sound
            }
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && profiles.size > 1) {
            val nextIdx = (idx + 1) % profiles.size
            tile.subtitle = "Tap → ${profiles[nextIdx]["name"]}"
        }

        tile.updateTile()
    }
}
