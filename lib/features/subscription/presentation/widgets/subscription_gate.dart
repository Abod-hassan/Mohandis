import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/widgets/loading_view.dart';

import '../notifiers/subscription_notifier.dart';
import 'subscription_view.dart';

/// Shows [child] to anyone with access to the panel, and the paywall to
/// everyone else.
///
/// **Fails open.** If the subscription state cannot be read — offline, a 500,
/// a response the app cannot parse — the child is shown. The server enforces
/// the gate on every panel route regardless, so the worst case is a screen that
/// renders and then reports 402; the alternative is locking a paying subscriber
/// out of what they bought because a request failed.
class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);

    return state.when(
      // The gate is re-read whenever the panel is opened; without this the tab
      // would blank to a spinner on every visit rather than showing what it
      // already knows while it checks.
      skipLoadingOnReload: true,
      loading: () => const LoadingView(),
      error: (_, __) => child,
      data: (data) => data.hasAccess
          ? child
          : SubscriptionView(state: data, showLockedCopy: true),
    );
  }
}
