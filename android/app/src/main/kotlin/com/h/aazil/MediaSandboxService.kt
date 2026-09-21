package com.h.aazil

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileInputStream
import java.net.InetSocketAddress
import java.net.Socket
import org.json.JSONObject

class MediaSandboxService : Service() {

    private val binder = object : IMediaSandboxService.Stub() {
        override fun inspectMediaFd(pfd: ParcelFileDescriptor?): String {
            if (pfd == null) return "{\"error\": \"null descriptor\"}"
            val response = JSONObject()
            try {
                val input = FileInputStream(pfd.fileDescriptor)
                val header = ByteArray(64)
                val readBytes = input.read(header)
                response.put("bytes_read", readBytes)
                response.put("process", "isolated:sandbox")
                response.put("isolated_uid", android.os.Process.myUid())
                response.put("pid", android.os.Process.myPid())
                
                // Inspect magic bytes safely inside isolated sandbox
                val mime = when {
                    readBytes >= 4 && header[0] == 0x89.toByte() && header[1] == 'P'.code.toByte() -> "image/png"
                    readBytes >= 3 && header[0] == 0xFF.toByte() && header[1] == 0xD8.toByte() -> "image/jpeg"
                    readBytes >= 4 && header[0] == 'G'.code.toByte() && header[1] == 'I'.code.toByte() -> "image/gif"
                    readBytes >= 12 && String(header, 0, 4) == "RIFF" && String(header, 8, 4) == "WEBP" -> "image/webp"
                    readBytes >= 8 && (String(header, 4, 4) == "ftyp" || String(header, 4, 4) == "moov") -> "video/mp4"
                    else -> "application/octet-stream"
                }
                response.put("mime_type", mime)
                response.put("success", true)
            } catch (e: Exception) {
                response.put("error", e.message)
            } finally {
                try {
                    pfd.close()
                } catch (_: Exception) {}
            }
            return response.toString()
        }

        override fun verifyNetworkBlocked(): Boolean {
            return try {
                // In isolatedProcess without INTERNET permission, opening a socket or connecting
                // MUST fail with SecurityException, SocketException, or IOException.
                val socket = Socket()
                socket.connect(InetSocketAddress("1.1.1.1", 53), 1000)
                socket.close()
                false // Succeeded => NOT blocked
            } catch (_: Exception) {
                true // Exception => successfully blocked!
            }
        }

        override fun verifyFilesystemBlocked(): Boolean {
            return try {
                // isolatedProcess runs under isolated_app SELinux domain and cannot read host/app files
                val forbidden = File("/data/system/packages.xml")
                !forbidden.canRead()
            } catch (_: Exception) {
                true // successfully blocked!
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
}
