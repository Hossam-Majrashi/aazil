import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../adaptive_screen_helper.dart';

class DesktopThemeScreen extends StatelessWidget {
  const DesktopThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = ThemeController.instance.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectTheme),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 580),
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectTheme,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.themeSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dark Mode Card
                        Expanded(
                          child: _buildDesktopThemeCard(
                            theme: theme,
                            title: l10n.darkMode,
                            hexBg: '#212327',
                            hexBtn: '#232627',
                            bgColor: const Color(0xFF212327),
                            btnColor: const Color(0xFF232627),
                            textColor: Colors.white,
                            isSelected: isDark,
                            onTap: () => ThemeController.instance.setThemeMode(
                              ThemeMode.dark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Light Mode Card
                        Expanded(
                          child: _buildDesktopThemeCard(
                            theme: theme,
                            title: l10n.lightMode,
                            hexBg: '#efeef1',
                            hexBtn: '#fefefe',
                            bgColor: const Color(0xFFEFEEF1),
                            btnColor: const Color(0xFFFEFEFE),
                            textColor: Colors.black87,
                            isSelected: !isDark,
                            onTap: () => ThemeController.instance.setThemeMode(
                              ThemeMode.light,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_complete', true);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdaptiveScreenHelper.getHomeScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopThemeCard({
    required ThemeData theme,
    required String title,
    required String hexBg,
    required String hexBtn,
    required Color bgColor,
    required Color btnColor,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Background: $hexBg',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Buttons & Icons: $hexBtn',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            // Mock UI widget inside card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: textColor.withValues(alpha: 0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Preview Button',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
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
