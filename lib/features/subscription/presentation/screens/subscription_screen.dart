import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../notifiers/subscription_notifier.dart';
import '../widgets/subscription_view.dart';

/// The subscription page as a destination — what you hold, and what else is on
/// offer. Reached from the panel: its strip, and every padlocked section row,
/// send you here. There is no in-place paywall any more — the panel itself is
/// open to everyone.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final state = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: context.l10n.subscriptionTitle),
      body: state.when(
        skipLoadingOnReload: true,
        // A failed background re-read (the approval poll) keeps the page up
        // rather than swapping it for an error; the next tick retries.
        skipError: true,
        loading: () => const CardListSkeleton(count: 3, height: 140, lines: 3),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(subscriptionProvider.notifier).refresh(),
        ),
        data: (data) => SubscriptionView(state: data),
      ),
    );
  }
}
