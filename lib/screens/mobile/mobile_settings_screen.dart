import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sandbox_status.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../../theme/app_theme.dart';
import '../../theme/locale_controller.dart';

class MobileSettingsScreen extends StatefulWidget {
  const MobileSettingsScreen({super.key});

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
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
        title: Text(l10n.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Sandbox Engine Status Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        l10n.sandboxStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sandboxInfoLabel(mechanism),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          SandboxManager.instance.securityArchitectureInfo,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRunningTest ? null : _runTest,
                      icon: _isRunningTest
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified, size: 18),
                      label: Text(l10n.testSandboxSecurity),
                    ),
                  ),
                  if (_testStatus != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.secondary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                l10n.testPassed,
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _testStatus!.statusDescription,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security Guarantees
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.securityGuarantees,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityRow(Icons.wifi_off, l10n.networkDenied, Colors.orange),
                  const SizedBox(height: 8),
                  _buildSecurityRow(Icons.folder_off, l10n.fsRestricted, Colors.cyan),
                  const SizedBox(height: 8),
                  _buildSecurityRow(Icons.shield_moon, l10n.syscallFilter, Colors.green),
                  const SizedBox(height: 8),
                  _buildSecurityRow(Icons.lock_outline, l10n.processIsolation, Colors.purpleAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences (Language & Theme Quick Switch)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settings,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text(l10n.darkMode),
                    subtitle: const Text('Dark (#212327) / Light (#efeef1)'),
                    value: isDark,
                    onChanged: (val) {
                      ThemeController.instance.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('العربية (RTL)'),
                    subtitle: Text(isArabic ? 'Arabic active' : 'English active'),
                    value: isArabic,
                    onChanged: (val) {
                      LocaleController.instance.setLocale(val ? const Locale('ar') : const Locale('en'));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Developer Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.developer,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '\u062d\u0633\u0627\u0645 \u062d\u0633\u0646 \u0645\u062c\u0631\u0634\u064a',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFCDCCCA)),
                  ),
                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFF262523)),
                  const SizedBox(height: 32),
                  _buildContactItem(
                    context,
                    icon: Icons.alternate_email_rounded,
                    label: '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                    value: 'Hossam.Majrashi@gmail.com',
                    onTap: () => _launchUrl('mailto:Hossam.Majrashi@gmail.com'),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    context,
                    icon: Icons.public_rounded,
                    label: '\u0627\u0644\u0645\u0648\u0642\u0639 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
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
    );
  }

  Widget _buildSecurityRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
