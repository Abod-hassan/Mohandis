import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../data/profile_setup_store.dart';
import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';

/// The step straight after registration: give the empty profile something to
/// show. Reached only via the router's `profileSetupPendingProvider` rule, and
/// left only by saving or skipping — both clear the flag, which is what
/// releases the redirect and lands the person on the feed.
///
/// The account exists at this point (contact + Identity user + session), and
/// the social profile has been auto-provisioned with the name from the
/// contact. Everything here is an edit to that row, so nothing is lost if the
/// person skips.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _headline = TextEditingController();
  final _about = TextEditingController();
  final _location = TextEditingController();
  final _industry = TextEditingController();
  final _website = TextEditingController();

  bool _openToWork = false;
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _headline.dispose();
    _about.dispose();
    _location.dispose();
    _industry.dispose();
    _website.dispose();
    super.dispose();
  }

  /// Seeds the fields from whatever the profile already has — once. Re-running
  /// on every rebuild would overwrite what the person is typing.
  void _hydrate(Profile profile) {
    if (_hydrated) return;
    _headline.text = profile.headline;
    _about.text = profile.about;
    _location.text = profile.location;
    _industry.text = profile.industry;
    _website.text = profile.website ?? '';
    _openToWork = profile.openToWork;
    _hydrated = true;
  }

  /// Clearing the flag is what releases the router; it then sends us to the
  /// feed on its own.
  ///
  /// [toSuggestions] overrides that landing for somebody who actually filled
  /// the form in: a network with nobody in it has nothing to show, so the
  /// useful next screen is people to connect to rather than a feed of three
  /// suggested posts. A SKIP goes straight to the feed — somebody who declined
  /// to say who they are is not asking to be introduced to anyone.
  Future<void> _leave({bool toSuggestions = false}) async {
    // The router is captured BEFORE the await, and `mounted` is deliberately
    // not consulted afterwards.
    //
    // `complete()` sets its state synchronously and only then awaits
    // SharedPreferences — so the refresh listener fires, the redirect sends
    // this screen to `/feed`, and the frame that unmounts it can land during
    // that platform round trip. Reading `context` after the await would then
    // be reading a dead element, and guarding on `mounted` would silently skip
    // the navigation that is the whole point of the flag.
    final router = GoRouter.of(context);
    await ref.read(profileSetupPendingProvider.notifier).complete();
    if (!toSuggestions) return;
    // After the flag, so the redirect no longer bounces this back.
    router.go('/welcome/connect');
  }

  Future<void> _save(AccountType accountType) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final result = await ref
        .read(profileNotifierProvider('me').notifier)
        .save({
          'headline': _headline.text.trim(),
          'about': _about.text.trim(),
          'location': _location.text.trim(),
          'industry': _industry.text.trim(),
          if (accountType == AccountType.company)
            'website': _website.text.trim(),
          if (accountType == AccountType.individual) 'openToWork': _openToWork,
        });

    if (!mounted) return;
    setState(() => _saving = false);

    await result.when(
      success: (_) async {
        if (!mounted) return;
        showRungToast(context, context.l10n.setupSaved);
        await _leave(toSuggestions: true);
      },
      failure: (e) async {
        if (!mounted) return;
        // Stays on the screen: the edits are still in the fields, and the
        // flag is untouched, so a retry costs one tap.
        showRungToast(context, arabicMessageForException(e), success: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final profile = ref.watch(profileNotifierProvider('me'));

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        showBack: false,
        title: l10n.setupTitle,
        actions: [
          TextButton(
            onPressed: _saving ? null : _leave,
            style: TextButton.styleFrom(foregroundColor: c.ink2),
            child: Text(l10n.setupSkip),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider('me').notifier).refresh(),
        ),
        data: (data) {
          _hydrate(data);
          final isCompany = data.accountType == AccountType.company;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              RungSpace.gutter,
              RungSpace.md,
              RungSpace.gutter,
              RungSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Text(
                isCompany ? l10n.setupSubtitleCompany : l10n.setupSubtitle,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink3),
              ),
              const SizedBox(height: RungSpace.lg),

              RungField(
                label: l10n.setupHeadline,
                hint: isCompany
                    ? l10n.setupHeadlineHintCompany
                    : l10n.setupHeadlineHint,
                controller: _headline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: RungSpace.md),

              RungField(
                label: l10n.setupAbout,
                hint: isCompany
                    ? l10n.setupAboutHintCompany
                    : l10n.setupAboutHint,
                controller: _about,
                maxLines: 5,
                height: 120,
              ),
              const SizedBox(height: RungSpace.md),

              RungField(
                label: l10n.setupLocation,
                hint: l10n.setupLocationHint,
                controller: _location,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: RungSpace.md),

              RungField(
                label: l10n.setupIndustry,
                hint: l10n.setupIndustryHint,
                controller: _industry,
                textInputAction: TextInputAction.next,
              ),

              if (isCompany) ...[
                const SizedBox(height: RungSpace.md),
                RungField(
                  label: l10n.setupWebsite,
                  controller: _website,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
              ] else ...[
                const SizedBox(height: RungSpace.md),
                RungToggleTile(
                  title: l10n.setupOpenToWork,
                  subtitle: l10n.setupOpenToWorkSubtitle,
                  value: _openToWork,
                  onChanged: (value) => setState(() => _openToWork = value),
                ),
              ],

              const SizedBox(height: RungSpace.lg),
              FilledButton(
                onPressed: _saving ? null : () => _save(data.accountType),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.setupSave),
              ),
            ],
          );
        },
      ),
    );
  }
}
