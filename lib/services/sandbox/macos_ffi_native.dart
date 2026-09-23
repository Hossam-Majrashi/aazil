import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef SandboxInitNative = Int32 Function(
  Pointer<Utf8> profile,
  Uint64 flags,
  Pointer<Pointer<Utf8>> errorbuf,
);
typedef SandboxInitDart = int Function(
  Pointer<Utf8> profile,
  int flags,
  Pointer<Pointer<Utf8>> errorbuf,
);

/// Native macOS FFI invocation of libsandbox.dylib's sandbox_init() C API.
bool callSandboxInit(String targetFilePath) {
  if (!Platform.isMacOS) return false;

  try {
    final lib = DynamicLibrary.open('/usr/lib/libsandbox.dylib');
    final sandboxInit = lib.lookupFunction<SandboxInitNative, SandboxInitDart>(
      'sandbox_init',
    );

    final profileStr = '''
(version 1)
(deny default)
(allow process-exec)
(allow sysctl-read)
(deny network*)
(allow file-read* (literal "$targetFilePath"))
(deny file-read* (subpath "/Users"))
(deny file-write*)
''';
    final profilePtr = profileStr.toNativeUtf8();
    final errorbufPtr = calloc<Pointer<Utf8>>();

    final rc = sandboxInit(profilePtr, 0, errorbufPtr);
    calloc.free(profilePtr);
    calloc.free(errorbufPtr);

    return (rc == 0);
  } catch (_) {
    return false;
  }
}
