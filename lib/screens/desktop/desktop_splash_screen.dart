import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../adaptive_screen_helper.dart';

class DesktopSplashScreen extends StatelessWidget {
  const DesktopSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mechanism = SandboxManager.instance.mechanismLabel;

    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 750;

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960, maxHeight: 620),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: isWide
                      ? Row(
                          children: [
                            // Left Column: Big Icon & Security Status
                            Expanded(
                              flex: 4,
                              child: _buildHeroIcon(theme, mechanism),
                            ),
                            const SizedBox(width: 48),
                            const VerticalDivider(width: 1),
                            const SizedBox(width: 48),
                            // Right Column: App Info & Entry point
                            Expanded(
                              flex: 5,
                              child: _buildDetailsColumn(context, l10n, theme),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeroIcon(theme, mechanism),
                              const SizedBox(height: 32),
                              _buildDetailsColumn(context, l10n, theme),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroIcon(ThemeData theme, String mechanism) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Image.asset(
              'assets/icon/export_512x512.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.shield_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  mechanism,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsColumn(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appName,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.appSubtitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.appDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AdaptiveScreenHelper.getLanguageScreen(),
              ),
            );
          },
          icon: const Icon(Icons.arrow_forward),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              l10n.splashContinue,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
