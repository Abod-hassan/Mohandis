import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/dashboard/presentation/notifiers/dashboard_notifier.dart';
import 'package:mohandis/features/panel/presentation/notifiers/panel_notifiers.dart';

import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/subscription_entities.dart';

/// Whether the panel is open to this viewer, and what it would cost.
///
/// NOT autoDispose: the gate is read on every visit to the panel tab, and a
/// provider that tore itself down between visits would make the tab flash a
/// spinner every time somebody switched away and back.
class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  /// The gate's position at the last read, so a plain re-read ([refresh], the
  /// approval poll) can tell the panel when an admin opened it. Only [_write]
  /// used to do that, so an approval picked up by a refresh showed "active"
  /// here while every panel screen kept its cached 402s.
  bool? _lastAccess;

  /// What the panel opened to at the last read. An admin switching a section
  /// free moves THIS and not [_lastAccess] — the viewer still holds no
  /// subscription — so without it every panel screen kept the 402s it had
  /// cached until the app was restarted.
  Set<PlanFeature>? _lastFeatures;

  @override
  Future<SubscriptionState> build() async {
    final result = await ref.watch(subscriptionRepositoryProvider).state();
    final next = result.when(success: (s) => s, failure: (e) => throw e);
    final before = _lastAccess;
    final beforeFeatures = _lastFeatures;
    final features = next.features.toSet();
    _lastAccess = next.hasAccess;
    _lastFeatures = features;
    final moved = (before != null && before != next.hasAccess) ||
        (beforeFeatures != null && !_sameFeatures(beforeFeatures, features));
    if (moved) {
      // Not synchronously: a provider may not invalidate others mid-build.
      Future.microtask(_invalidatePanel);
    }
    return next;
  }

  Future<Result<SubscriptionState, AppException>> start(
    String planId,
    BillingCycle cycle,
  ) => _write(
    () => ref.read(subscriptionRepositoryProvider).start(planId, cycle),
  );

  /// Prices a plan change. Read-only, so it deliberately does NOT go through
  /// [_write]: there is no new state to publish and blanking the screen to a
  /// spinner to fill in a confirmation sheet would be a worse trade than the
  /// round trip already is.
  Future<Result<PlanChangeQuote, AppException>> previewChange(
    String planId,
    BillingCycle cycle,
  ) => ref.read(subscriptionRepositoryProvider).previewChange(planId, cycle);

  Future<Result<SubscriptionState, AppException>> change(
    String planId,
    BillingCycle cycle,
  ) => _write(
    () => ref.read(subscriptionRepositoryProvider).change(planId, cycle),
  );

  Future<Result<SubscriptionState, AppException>> setAutoRenew(bool enabled) =>
      _write(() => ref.read(subscriptionRepositoryProvider).setAutoRenew(enabled));

  Future<Result<SubscriptionState, AppException>> cancel() =>
      _write(() => ref.read(subscriptionRepositoryProvider).cancel());

  /// Re-reads the gate.
  ///
  /// `invalidateSelf` rather than assigning `AsyncValue.loading()` and awaiting
  /// `build` by hand: a bare loading value carries no previous data, so
  /// `isReloading` is false and every `skipLoadingOnReload` reader blanks to a
  /// spinner — which is the whole panel. It is also the only form that
  /// re-registers `build`'s `ref.watch` dependencies properly.
  void refresh() => ref.invalidateSelf();

  Future<Result<SubscriptionState, AppException>> _write(
    Future<Result<SubscriptionState, AppException>> Function() action,
  ) async {
    final before = state.valueOrNull?.hasAccess;
    final result = await action();

    result.when(
      success: (next) {
        state = AsyncValue.data(next);
        _lastAccess = next.hasAccess;
        _lastFeatures = next.features.toSet();
        // Only when the gate actually moved. Starting a subscription leaves it
        // pending and changes nothing, and invalidating six providers to
        // redraw the same screens would throw away every panel read for a
        // request that granted nothing.
        if (before != null && before != next.hasAccess) _invalidatePanel();
      },
      failure: (_) {},
    );

    return result;
  }

  static bool _sameFeatures(Set<PlanFeature> a, Set<PlanFeature> b) =>
      a.length == b.length && a.containsAll(b);

  /// Everything behind the gate. All of it read through providers that cached
  /// whatever the server said while the gate was in its previous position —
  /// including, on the way in, a page of 402s.
  void _invalidatePanel() {
    ref.invalidate(dashboardNotifierProvider);
    ref.invalidate(courseListProvider);
    ref.invalidate(courseProvider);
    ref.invalidate(courseLecturesProvider);
    ref.invalidate(notesProvider);
    ref.invalidate(documentsProvider);
    ref.invalidate(legalRequestsProvider);
    ref.invalidate(assistantConversationsProvider);
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      SubscriptionNotifier.new,
    );
