import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../../models/sandbox_status.dart';
import 'android_sandbox.dart';
import 'ios_sandbox.dart';
import 'linux_sandbox.dart';
import 'macos_sandbox.dart';
import 'sandbox_interface.dart';
import 'web_sandbox.dart';
import 'windows_sandbox.dart';
import '../media_metadata_reader.dart';

class SandboxManager {
  static final SandboxManager instance = SandboxManager._internal();

  late final SandboxProvider _provider;

  SandboxManager._internal() {
    if (kIsWeb) {
      _provider = WebSandboxProvider();
    } else if (Platform.isLinux) {
      _provider = LinuxSandboxProvider();
    } else if (Platform.isWindows) {
      _provider = WindowsSandboxProvider();
    } else if (Platform.isMacOS) {
      _provider = MacOSSandboxProvider();
    } else if (Platform.isAndroid) {
      _provider = AndroidSandboxProvider();
    } else if (Platform.isIOS) {
      _provider = IOSSandboxProvider();
    } else {
      _provider = LinuxSandboxProvider();
    }
  }

  SandboxProvider get provider => _provider;

  String get currentPlatform => _provider.platformName;
  String get mechanismLabel => _provider.mechanismLabel;
  String get securityArchitectureInfo => _provider.securityArchitectureInfo;

  Future<SandboxStatus> runSecurityTest([String? targetFilePath]) async {
    final path = targetFilePath ?? 'assets/icon/app_icon.png';
    return await _provider.testIsolation(path);
  }

  Future<Map<String, dynamic>> inspectMedia(String targetFilePath) async {
    final status = await _provider.inspectMedia(targetFilePath);
    final mediaMeta = await MediaMetadataReader.instance.readMetadata(targetFilePath);
    return {
      ...status,
      ...mediaMeta,
    };
  }
}
