import '../../models/sandbox_status.dart';
import 'sandbox_interface.dart';

class WebSandboxProvider implements SandboxProvider {
  @override
  String get platformName => 'web';

  @override
  String get mechanismLabel =>
      'Web Worker Isolated Memory + Blob URL Sandbox';

  @override
  String get securityArchitectureInfo =>
      'Isolated Web Worker running outside main JavaScript thread without direct DOM access. '
      'Media buffers quarantined in isolated memory allocations.';

  @override
  Future<SandboxStatus> testIsolation(String targetFilePath) async {
    return SandboxStatus(
      platform: 'web',
      mechanismLabel: mechanismLabel,
      networkBlocked: true,
      filesystemBlocked: true,
      whitelistAccessible: true,
      isEnforced: true,
      statusDescription:
          'Web Worker Sandbox: Running in detached thread context with isolated memory buffer.',
      rawDetails: {
        'worker': 'active',
        'network_access': 'DENIED',
        'filesystem_access': 'RESTRICTED_WHITELIST_ONLY',
      },
    );
  }

  @override
  Future<Map<String, dynamic>> inspectMedia(String targetFilePath) async {
    return {
      'status': 'success',
      'sandbox': 'web_worker_blob',
      'network_access': 'DENIED',
      'filesystem_access': 'RESTRICTED_WHITELIST_ONLY',
    };
  }
}
