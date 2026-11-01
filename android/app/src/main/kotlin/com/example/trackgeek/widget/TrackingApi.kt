package com.example.trackgeek.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Path
import android.graphics.RectF
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

object TrackingApi {
    const val SECTION_WATCHING = "watching"
    const val SECTION_READING = "reading"

    private const val DEFAULT_BASE_URL = "https://api.trackgeek.net"
    private const val LIMIT = 6

    private class Source(
        val slug: String,
        val envelope: String,
        val mediaKey: String,
        val statuses: List<String>,
        val reading: Boolean,
    )

    private val sources = mapOf(
        SECTION_WATCHING to listOf(
            Source("anime", "animeProgresses", "anime", listOf("Watching", "Rewatching"), false),
            Source("tv", "tvShowProgresses", "tvShow", listOf("Watching", "Rewatching"), false),
        ),
        SECTION_READING to listOf(
            Source("manga", "mangaProgresses", "manga", listOf("Reading", "Rereading"), true),
            Source("book", "bookProgresses", "book", listOf("Reading", "Rereading"), true),
        ),
    )

    sealed class Result {
        data class Ok(val items: List<TrackingItem>) : Result()
        data object SignedOut : Result()
        data object Failure : Result()
    }

    class TrackingItem(
        val title: String,
        val imageUrl: String?,
        val progressLabel: String?,
        val updatedAt: String,
        var cover: Bitmap?,
    )

    fun fetch(context: Context, section: String): Result {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val token = prefs.getString("flutter.trackgeek.session.token", null)
        val userId = prefs.getString("flutter.trackgeek.session.userId", null)
        if (token.isNullOrEmpty() || userId.isNullOrEmpty()) return Result.SignedOut
        val base = prefs.getString("flutter.trackgeek.server.url", null)
            ?.trimEnd('/')
            ?: DEFAULT_BASE_URL

        val items = mutableListOf<TrackingItem>()
        for (source in sources[section].orEmpty()) {
            for (status in source.statuses) {
                val json = get(
                    "$base/${source.slug}/progress/" +
                        "?userId=$userId&status=$status" +
                        "&sortBy=updatedAt&sortOrder=desc" +
                        "&page=1&itemsPerPage=$LIMIT",
                    token,
                ) ?: return Result.Failure
                val envelope = json.optJSONObject(source.envelope) ?: continue
                val pageItems = envelope.optJSONArray("items") ?: continue
                for (i in 0 until pageItems.length()) {
                    val row = pageItems.optJSONObject(i) ?: continue
                    val media = row.optJSONObject(source.mediaKey) ?: continue
                    val title = media.optString("title").ifEmpty {
                        media.optString("name")
                    }
                    val image = firstString(
                        media.optString("imageUrl"),
                        media.optString("coverUrl"),
                        media.optString("posterUrl"),
                    )
                    items.add(
                        TrackingItem(
                            title = title,
                            imageUrl = image,
                            progressLabel = progressLabel(row, media, source.reading),
                            updatedAt = row.optString("updatedAt"),
                            cover = null,
                        ),
                    )
                }
            }
        }
        items.sortByDescending { it.updatedAt }
        return Result.Ok(items.take(LIMIT))
    }

    private fun firstString(vararg values: String): String? =
        values.firstOrNull { it.isNotEmpty() }

    private fun progressLabel(
        row: JSONObject,
        media: JSONObject,
        reading: Boolean,
    ): String? {
        var current: Int? = null
        var total: Int? = null
        if (reading) {
            current = row.optInt("chaptersRead", -1).takeIf { it >= 0 }
            val rawTotal = when {
                row.has("totalPages") -> row.optInt("totalPages", 0)
                else -> media.optInt(
                    "numberOfPages",
                    media.optInt("numberOfChapters", 0),
                )
            }
            total = rawTotal.takeIf { it > 0 }
        } else {
            val episode = row.optJSONObject("episodeProgress")
            if (episode != null) {
                current = episode.optInt("current", -1).takeIf { it >= 0 }
                total = episode.optInt("total", 0).takeIf { it > 0 }
            }
        }
        if (current == null) return null
        return "$current/${total?.toString() ?: "?"}"
    }

    private fun get(url: String, token: String): JSONObject? = try {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15000
            readTimeout = 15000
            setRequestProperty("Accept", "application/json")
            setRequestProperty("X-TrackGeek-Version", "1.0.0")
            setRequestProperty(
                "X-TrackGeek-Language",
                Locale.getDefault().toLanguageTag(),
            )
            setRequestProperty("Authorization", "Bearer $token")
            instanceFollowRedirects = true
        }
        try {
            if (conn.responseCode !in 200..299) {
                null
            } else {
                conn.inputStream.bufferedReader().use { JSONObject(it.readText()) }
            }
        } finally {
            conn.disconnect()
        }
    } catch (_: Exception) {
        null
    }

    fun downloadCover(url: String, cornersDp: Float, density: Float): Bitmap? = try {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15000
            readTimeout = 15000
            instanceFollowRedirects = true
        }
        val bitmap = try {
            if (conn.responseCode !in 200..299) null
            else BitmapFactory.decodeStream(conn.inputStream)
        } finally {
            conn.disconnect()
        }
        bitmap?.let {
            val maxW = 100f * density
            val maxH = 150f * density
            val scale = minOf(1f, maxW / it.width, maxH / it.height)
            val scaled = if (scale < 1f) {
                Bitmap.createScaledBitmap(
                    it,
                    (it.width * scale).toInt().coerceAtLeast(1),
                    (it.height * scale).toInt().coerceAtLeast(1),
                    true,
                )
            } else it
            roundCorners(scaled, cornersDp * density)
        }
    } catch (_: Exception) {
        null
    }

    private fun roundCorners(source: Bitmap, radius: Float): Bitmap {
        val out = Bitmap.createBitmap(
            source.width,
            source.height,
            Bitmap.Config.ARGB_8888,
        )
        val canvas = Canvas(out)
        val path = Path().apply {
            addRoundRect(
                RectF(0f, 0f, source.width.toFloat(), source.height.toFloat()),
                radius,
                radius,
                Path.Direction.CW,
            )
        }
        canvas.clipPath(path)
        canvas.drawBitmap(source, 0f, 0f, null)
        return out
    }
}
