import '../../models/sandbox_status.dart';

abstract class SandboxProvider {
  String get platformName;
  String get mechanismLabel;
  String get securityArchitectureInfo;

  Future<SandboxStatus> testIsolation(String targetFilePath);
  Future<Map<String, dynamic>> inspectMedia(String targetFilePath);
}
