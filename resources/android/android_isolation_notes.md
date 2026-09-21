# Android Isolated Process Sandboxing Model

On Android, `Aazil` implements sandboxing using:
1. `android:process=":sandbox"` combined with `android:isolatedProcess="true"` for `MediaSandboxService`.
2. The isolated service runs with a dedicated UID in the `isolated_app` SELinux domain.
3. No `android.permission.INTERNET` is requested or granted.
4. Host app memory and filesystem are completely inaccessible from the sandbox process.
5. Communication occurs strictly over a narrow AIDL/Binder interface (`IMediaSandboxService.aidl`).
