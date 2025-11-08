package com.ryan.anymex

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import java.io.BufferedReader
import android.view.KeyEvent
import java.io.InputStreamReader

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app/architecture"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentArchitecture" -> {
                    val architecture = getCurrentArchitecture()
                    result.success(architecture)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getCurrentArchitecture(): String {
        return try {
            val primaryAbi = Build.SUPPORTED_ABIS?.firstOrNull()
            if (primaryAbi != null) {
                when {
                    primaryAbi.contains("arm64") || primaryAbi.contains("v8a") -> "arm64"
                    primaryAbi.contains("arm") || primaryAbi.contains("v7a") -> "arm32"
                    primaryAbi.contains("x86_64") -> "x86_64"
                    primaryAbi.contains("x86") -> "x86"
                    else -> primaryAbi
                }
            } else {
                getSystemProperty("ro.product.cpu.abi") ?: "unknown"
            }
        } catch (e: Exception) {
            e.printStackTrace()
            "unknown"
        }
    }

    
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        // Handle DPAD navigation for Android TV remote
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER -> {
                    // Let Flutter handle the "enter" — send as ACTION_BUTTON_PRESS if needed
                    return super.dispatchKeyEvent(event)
                }
                KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN,
                KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_DPAD_RIGHT -> {
                    // Let the framework handle focus movement; still pass to super.
                    return super.dispatchKeyEvent(event)
                }
                KeyEvent.KEYCODE_BACK -> {
                    // map to Android back
                    return super.dispatchKeyEvent(event)
                }
                else -> {}
            }
        }
        return super.dispatchKeyEvent(event)
    }
private fun getSystemProperty(property: String): String? {
        return try {
            val process = Runtime.getRuntime().exec("getprop $property")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val result = reader.readLine()
            reader.close()
            process.waitFor()
            result
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}