class SandboxStatus {
  final String platform;
  final String mechanismLabel;
  final bool networkBlocked;
  final bool filesystemBlocked;
  final bool whitelistAccessible;
  final bool isEnforced;
  final int? isolatedPid;
  final String statusDescription;
  final Map<String, dynamic> rawDetails;

  SandboxStatus({
    required this.platform,
    required this.mechanismLabel,
    required this.networkBlocked,
    required this.filesystemBlocked,
    required this.whitelistAccessible,
    required this.isEnforced,
    this.isolatedPid,
    required this.statusDescription,
    this.rawDetails = const {},
  });

  factory SandboxStatus.initial(String platform, String mechanism) {
    return SandboxStatus(
      platform: platform,
      mechanismLabel: mechanism,
      networkBlocked: true,
      filesystemBlocked: true,
      whitelistAccessible: true,
      isEnforced: true,
      statusDescription: 'Enforced via OS Isolation Mechanism',
    );
  }
}
