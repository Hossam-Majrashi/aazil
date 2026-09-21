package com.h.aazil

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.h.aazil/sandbox"
    private var sandboxService: IMediaSandboxService? = null
    private var isBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            sandboxService = IMediaSandboxService.Stub.asInterface(service)
            isBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            sandboxService = null
            isBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Bind to isolated sandbox service
        val intent = Intent(this, MediaSandboxService::class.java)
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "testIsolation" -> {
                    if (sandboxService == null) {
                        result.error("SERVICE_UNAVAILABLE", "Isolated sandbox service not bound", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val netBlocked = sandboxService!!.verifyNetworkBlocked()
                        val fsBlocked = sandboxService!!.verifyFilesystemBlocked()
                        val map = mapOf(
                            "platform" to "android",
                            "sandbox_mechanism" to "Android isolatedProcess (:sandbox) + Binder/AIDL",
                            "network_blocked" to netBlocked,
                            "filesystem_blocked" to fsBlocked,
                            "whitelist_accessible" to true,
                            "security_status" to if (netBlocked && fsBlocked) "ENFORCED" else "DEGRADED"
                        )
                        result.success(map)
                    } catch (e: Exception) {
                        result.error("ISOLATION_ERROR", e.message, null)
                    }
                }
                "inspectMedia" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null || sandboxService == null) {
                        result.error("INVALID_ARGS", "Missing filePath or service unavailable", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(filePath)
                        val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                        val jsonStr = sandboxService!!.inspectMediaFd(pfd)
                        result.success(jsonStr)
                    } catch (e: Exception) {
                        result.error("INSPECT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
    }
}
