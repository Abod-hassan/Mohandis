import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/theme/theme_mode_notifier.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/auth/presentation/notifiers/auth_notifier.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

/// App settings.
///
/// Deliberately short: it lists only what the app can actually change. Profile
/// fields (name, headline, privacy, open-to-work) live on the edit-profile
/// screen and are linked from here rather than duplicated.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.only(bottom: RungSpace.lg),
        children: [
          RungSection(
            title: l10n.settingsAppearance,
            child: Column(
              children: [
                for (final option in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    value: option,
                    groupValue: mode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).set(value);
                      }
                    },
                    title: Text(
                      _themeLabel(l10n, option),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          RungSection(
            title: l10n.settingsSaved,
            child: Column(
              children: [
                _Row(
                  icon: Icons.bookmark_border,
                  label: l10n.savedPostsTitle,
                  onTap: () => context.push('/saved/posts'),
                ),
                _Row(
                  icon: Icons.work_outline,
                  label: l10n.savedJobsTitle,
                  onTap: () => context.push('/saved/jobs'),
                ),
              ],
            ),
          ),
          RungSection(
            title: l10n.settingsAccount,
            child: Column(
              children: [
                _Row(
                  icon: Icons.person_outline,
                  label: l10n.profileEdit,
                  onTap: () => context.push('/profile/me/edit'),
                ),
                _Row(
                  icon: Icons.logout,
                  label: l10n.settingsLogout,
                  danger: true,
                  onTap: () => confirmAndLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.settingsThemeSystem,
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
      };
}

/// Asks first, then signs out.
///
/// No navigation afterwards: the router redirects to `/auth` the moment the
/// session goes null, so pushing a route here would race it.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.settingsLogoutTitle),
      content: Text(l10n.settingsLogoutBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.settingsLogout),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(authNotifierProvider.notifier).logout();
  } catch (e) {
    if (!context.mounted) return;
    showRungToast(context, arabicMessageForException(e), success: false);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final color = danger ? c.red : c.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (!danger)
              Icon(Icons.chevron_right, size: 18, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
