import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/config/legal_links.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/theme/theme_mode_notifier.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/features/shared/auth/presentation/notifiers/auth_notifier.dart';
import 'package:mohandis/l10n/l10n.dart';

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
    final me = ref.watch(profileNotifierProvider('me')).valueOrNull;

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
          // Privacy. The same switch lives on Edit Profile; it is here as well
          // because this is where people look for it.
          if (me != null && !me.isCompany)
            RungSection(
              title: l10n.settingsPrivacy,
              child: RungToggleTile(
                title: l10n.settingsPrivateAccount,
                subtitle: me.isPrivate
                    ? l10n.settingsPrivateAccountOn
                    : l10n.settingsPrivateAccountOff,
                value: me.isPrivate,
                onChanged: (value) async {
                  final result = await ref
                      .read(profileNotifierProvider('me').notifier)
                      .save({'isPrivate': value});
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {},
                    failure: (e) => showRungToast(
                      context,
                      arabicMessageForException(e),
                      success: false,
                    ),
                  );
                },
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
                _Row(
                  icon: Icons.school_outlined,
                  label: l10n.myCoursesTitle,
                  onTap: () => context.push('/panel/courses/mine'),
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
                // The permanent way to the optional second factor. The offer
                // on the profile step is a one-time nudge; this is where a
                // person goes looking for it afterwards — or to move it to a
                // different address.
                _Row(
                  icon: Icons.shield_outlined,
                  label: l10n.emailVerifyTitle,
                  onTap: () => context.push('/settings/email'),
                ),
                _Row(
                  icon: Icons.privacy_tip_outlined,
                  label: l10n.settingsPrivacyPolicy,
                  onTap: () => openPrivacyPolicy(context),
                ),
                _Row(
                  icon: Icons.description_outlined,
                  label: l10n.settingsTerms,
                  onTap: () => openTerms(context),
                ),
                _Row(
                  icon: Icons.logout,
                  label: l10n.settingsLogout,
                  danger: true,
                  onTap: () => confirmAndLogout(context, ref),
                ),
                // Required by App Store guideline 5.1.1(v): an app with sign-up
                // must let the person delete the account from inside the app.
                _Row(
                  icon: Icons.delete_forever_outlined,
                  label: l10n.settingsDeleteAccount,
                  danger: true,
                  onTap: () => _confirmAndDeleteAccount(context, ref),
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

/// Asks twice in effect — a dialog that names exactly what goes — then deletes
/// the account and signs out. A blocking progress dialog while it runs: the
/// request removes a lot of rows, and a second tap must not start it again.
Future<void> _confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Text(l10n.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  final result =
      await ref.read(authNotifierProvider.notifier).deleteAccount();
  navigator.pop();

  result.when(
    // The router sends the signed-out app to /auth; the toast goes through
    // the messenger captured above, because this screen is on its way out.
    success: (_) => messenger?.showSnackBar(
      SnackBar(content: Text(l10n.toastAccountDeleted)),
    ),
    failure: (e) {
      if (!context.mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
    },
  );
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
