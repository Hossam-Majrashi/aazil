import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../adaptive_screen_helper.dart';

class WebThemeScreen extends StatelessWidget {
  const WebThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.palette_outlined, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.selectTheme,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.themeSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 36),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 580;
                    final darkCard = _buildThemeCard(
                      title: l10n.darkMode,
                      hexBg: '#212327',
                      hexBtn: '#232627',
                      bgColor: const Color(0xFF212327),
                      btnColor: const Color(0xFF232627),
                      textColor: Colors.white,
                      isSelected: isDark,
                      theme: theme,
                      onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
                    );
                    final lightCard = _buildThemeCard(
                      title: l10n.lightMode,
                      hexBg: '#efeef1',
                      hexBtn: '#fefefe',
                      bgColor: const Color(0xFFEFEEF1),
                      btnColor: const Color(0xFFFEFEFE),
                      textColor: Colors.black87,
                      isSelected: !isDark,
                      theme: theme,
                      onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: darkCard),
                          const SizedBox(width: 20),
                          Expanded(child: lightCard),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          darkCard,
                          const SizedBox(height: 16),
                          lightCard,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_complete', true);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => AdaptiveScreenHelper.getHomeScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 6.0,
                    ),
                    child: Text(
                      l10n.splashContinue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildThemeCard({
    required String title,
    required String hexBg,
    required String hexBtn,
    required Color bgColor,
    required Color btnColor,
    required Color textColor,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'BG: $hexBg  •  Controls: $hexBtn',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.75),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette, size: 16, color: textColor.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Text(
                    'Preview Button',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
