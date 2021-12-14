package com.yassinebebba.bebba
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this.flutterEngine as FlutterEngine)
        Notifications.createNotificationChannels(this)
//        val flutterView = FlutterView(context)
//        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "com.yassinebebba.bebba/background_service").apply {
//            setMethodCallHandler { method, result ->
//                if (method.method == "startService") {
//                    val callbackRawHandle = method.arguments as Long
//                    BackgroundService.startService(this@MainActivity, callbackRawHandle)
//                    result.success(null)
//                } else {
//                    result.notImplemented()
//                }
//            }
//        }
//        val notificationManager: NotificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
//        notificationManager.createNotificationChannel(this as MainActivity)

//        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "com.yassinebebba.bebba/app_retain").apply {
//            setMethodCallHandler { method, result ->
//                if (method.method == "sendToBackground") {
//                    moveTaskToBack(true)
//                    result.success(null)
//                } else {
//                    result.notImplemented()
//                }
//            }
//        }
    }
}
