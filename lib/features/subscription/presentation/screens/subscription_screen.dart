import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../notifiers/subscription_notifier.dart';
import '../widgets/subscription_view.dart';

/// The subscription page as a destination — what you hold, and what else is on
/// offer. Reached from the panel; the paywall itself is the same view rendered
/// in place by `SubscriptionGate`.
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
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(subscriptionProvider.notifier).refresh(),
        ),
        data: (data) => SubscriptionView(state: data),
      ),
    );
  }
}
