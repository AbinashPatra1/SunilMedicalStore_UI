package com.sunilmedical.store

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Short confirmation beep for a successful barcode scan (see
        // lib/core/utils/scan_beep.dart) — a system tone, so no audio asset
        // or extra package is needed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.sunilmedical.store/beep")
            .setMethodCallHandler { call, result ->
                if (call.method == "beep") {
                    try {
                        val tone = ToneGenerator(AudioManager.STREAM_MUSIC, 90)
                        tone.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
                        android.os.Handler(mainLooper).postDelayed({ tone.release() }, 400)
                    } catch (_: RuntimeException) {
                        // No audio output available — a missing beep isn't worth failing over.
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
