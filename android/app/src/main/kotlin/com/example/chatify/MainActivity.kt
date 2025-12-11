package com.example.chatify

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pipEnabled = false
    private val CHANNEL = "chatify/pip"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chatify/pip")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enablePip" -> {
                        pipEnabled = true
                        result.success(null)
                    }
                    "disablePip" -> {
                        pipEnabled = false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()

        if (pipEnabled) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16))
                .build()

            enterPictureInPictureMode(params)
        }
    }
    override fun onPictureInPictureModeChanged(isInPip: Boolean) {
        super.onPictureInPictureModeChanged(isInPip)

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
            .invokeMethod("pipStatus", isInPip)
    }
}

