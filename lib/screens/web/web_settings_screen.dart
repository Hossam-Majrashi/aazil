import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sandbox_status.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../../theme/app_theme.dart';
import '../../theme/locale_controller.dart';

class WebSettingsScreen extends StatefulWidget {
  const WebSettingsScreen({super.key});

  @override
  State<WebSettingsScreen> createState() => _WebSettingsScreenState();
}

class _WebSettingsScreenState extends State<WebSettingsScreen> {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  l10n.settings,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.settingsDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Sandbox Engine Info Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              l10n.sandboxStatus,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.sandboxInfoLabel(mechanism),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          SandboxManager.instance.securityArchitectureInfo,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
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
                              : const Icon(Icons.security_update_good, size: 18),
                          label: Text(l10n.testSandboxSecurity),
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
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: theme.colorScheme.secondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _testStatus!.statusDescription,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Security Guarantees Grid
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.securityGuarantees,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildChip(Icons.wifi_off, l10n.networkDenied, Colors.orange),
                            _buildChip(Icons.folder_delete, l10n.fsRestricted, Colors.cyan),
                            _buildChip(Icons.verified, l10n.syscallFilter, Colors.green),
                            _buildChip(Icons.memory, l10n.processIsolation, Colors.purpleAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Preferences Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectTheme,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SwitchListTile(
                          title: Text(l10n.darkMode),
                          subtitle: const Text('#212327 / #232627'),
                          value: isDark,
                          onChanged: (v) {
                            ThemeController.instance.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('العربية (RTL)'),
                          subtitle: Text(isArabic ? 'Arabic RTL Active' : 'English LTR Active'),
                          value: isArabic,
                          onChanged: (v) {
                            LocaleController.instance.setLocale(v ? const Locale('ar') : const Locale('en'));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Developer Section
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
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
