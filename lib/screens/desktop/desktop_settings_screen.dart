import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sandbox_status.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../../theme/app_theme.dart';
import '../../theme/locale_controller.dart';

class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  SandboxStatus? _testStatus;
  bool _isRunningTest = false;

  Future<void> _runTest() async {
    setState(() => _isRunningTest = true);
    final status = await SandboxManager.instance.runSecurityTest();
    if (mounted) {
      setState(() {
        _testStatus = status;
        _isRunningTest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;
    final isArabic = LocaleController.instance.isRtl;
    final mechanism = SandboxManager.instance.mechanismLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.appName} — ${l10n.settings}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Security Guarantees & Preferences
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.securityGuarantees,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSecurityTile(
                                Icons.wifi_off,
                                l10n.networkDenied,
                                'Zero socket creation or internet routing permitted',
                                Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _buildSecurityTile(
                                Icons.folder_off,
                                l10n.fsRestricted,
                                'Confined to temporary mount with only target file',
                                Colors.cyan,
                              ),
                              const SizedBox(height: 12),
                              _buildSecurityTile(
                                Icons.shield,
                                l10n.syscallFilter,
                                'Kernel BPF filter intercepts & denies forbidden syscalls',
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildSecurityTile(
                                Icons.layers,
                                l10n.processIsolation,
                                'Unprivileged namespace / Low integrity execution',
                                Colors.purpleAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.settings,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text(l10n.darkMode),
                                subtitle: const Text('Dark (#212327) / Light (#efeef1)'),
                                value: isDark,
                                onChanged: (val) {
                                  ThemeController.instance.setThemeMode(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                                },
                              ),
                              SwitchListTile(
                                title: const Text('العربية (RTL)'),
                                subtitle: Text(isArabic ? 'Arabic RTL Active' : 'English LTR Active'),
                                value: isArabic,
                                onChanged: (val) {
                                  LocaleController.instance.setLocale(
                                    val ? const Locale('ar') : const Locale('en'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Developer Section
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.developer,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'حسام حسن مجرشي',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFCDCCCA)),
                              ),
                              const SizedBox(height: 40),
                              const Divider(color: Color(0xFF262523)),
                              const SizedBox(height: 32),
                              _buildContactItem(
                                context,
                                icon: Icons.alternate_email_rounded,
                                label: 'البريد الإلكتروني',
                                value: 'Hossam.Majrashi@gmail.com',
                                onTap: () => _launchUrl('mailto:Hossam.Majrashi@gmail.com'),
                              ),
                              const SizedBox(height: 16),
                              _buildContactItem(
                                context,
                                icon: Icons.public_rounded,
                                label: 'الموقع الإلكتروني',
                                value: 'hossam-majrashi.github.io/Works/',
                                onTap: () => _launchUrl('https://hossam-majrashi.github.io/Works/'),
                              ),
                              const SizedBox(height: 16),
                              _buildContactItem(
                                context,
                                icon: Icons.code_rounded,
                                label: 'GitHub',
                                value: 'github.com/Hossam-Majrashi',
                                onTap: () => _launchUrl('https://github.com/Hossam-Majrashi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Active Sandbox Engine & Live Test Console
                Expanded(
                  flex: 6,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.dns, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.sandboxStatus,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      l10n.sandboxInfoLabel(mechanism),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Architecture Breakdown:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  SandboxManager.instance.securityArchitectureInfo,
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isRunningTest ? null : _runTest,
                            icon: _isRunningTest
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_circle_filled, size: 20),
                            label: Text(l10n.testSandboxSecurity),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141618),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'ISOLATION TEST LOG',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_testStatus != null)
                                          Text(
                                            '[STATUS: ${_testStatus!.isEnforced ? "ENFORCED" : "DEGRADED"}]',
                                            style: const TextStyle(
                                              color: Colors.cyanAccent,
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const Divider(color: Colors.white12, height: 16),
                                    if (_testStatus == null)
                                      const Text(
                                        'Ready. Click "Run Sandbox Security Test" to trigger kernel isolation verification.\n'
                                        'Validates network socket denial and whitelist access control.',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        'Platform: ${_testStatus!.platform.toUpperCase()}\n'
                                        'Mechanism: ${_testStatus!.mechanismLabel}\n'
                                        'Network Blocked: ${_testStatus!.networkBlocked} (socket blocked)\n'
                                        'Filesystem Restricted: ${_testStatus!.filesystemBlocked}\n'
                                        'Whitelist Accessible: ${_testStatus!.whitelistAccessible}\n'
                                        'Isolated PID: ${_testStatus!.isolatedPid ?? 1}\n'
                                        'Result: ${_testStatus!.statusDescription}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
