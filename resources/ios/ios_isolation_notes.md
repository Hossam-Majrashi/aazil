# iOS Sandbox Isolation Model

On iOS, third-party applications are strictly prohibited by kernel-enforced sandboxing from spawning arbitrary child processes (via `fork`, `execve`, or posix_spawn).

To provide genuine process-level isolation:
1. Media decoding is dispatched into a detached `WKWebView` instance.
2. Apple executes `WKWebView`'s HTML5 media engine out-of-process inside `com.apple.WebKit.WebContent`.
3. The `WebContent` process runs in Apple's dedicated kernel sandbox, preventing malicious media payloads from compromising the main application address space.
4. The UX displays this as: **"Sandbox: OS-assisted isolation (WebKit WebContent sandbox)"**.
