import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/subscription_entities.dart';

/// Paid access to the engineer panel.
abstract class SubscriptionRepository {
  /// Whether the panel is gated, whether this caller is through, what they
  /// hold and what is on offer — one read, because the app asks it before
  /// drawing the panel at all.
  Future<Result<SubscriptionState, AppException>> state();

  /// Requests a subscription on a plan, at one of its billing cycles.
  ///
  /// Grants NOTHING on its own: there is no payment rail, so the row is
  /// created pending and an administrator activates it. The returned state
  /// reflects that — `hasAccess` does not flip on a successful call.
  ///
  /// [cycle] is required rather than defaulted, all the way down to the route:
  /// a month and a year differ by an order of magnitude, so an omitted cycle
  /// has to be an error, never a guess.
  Future<Result<SubscriptionState, AppException>> start(
    String planId,
    BillingCycle cycle,
  );

  /// Prices a move from the RUNNING term to a different plan or cycle.
  ///
  /// Changes nothing — it exists so the subscriber sees what happens to the
  /// days they have already paid for before committing to it.
  Future<Result<PlanChangeQuote, AppException>> previewChange(
    String planId,
    BillingCycle cycle,
  );

  /// Requests that move.
  ///
  /// Pending like any other purchase: the current term keeps running, and the
  /// two hand over the moment an administrator activates the change. The quote
  /// is recomputed server-side, so a stale preview cannot become a wrong charge.
  Future<Result<SubscriptionState, AppException>> change(
    String planId,
    BillingCycle cycle,
  );

  /// Turns automatic renewal on or off for the current term.
  ///
  /// Does not change access either way — it decides what happens when the term
  /// ends, which is why it is a separate action from cancelling.
  Future<Result<SubscriptionState, AppException>> setAutoRenew(bool enabled);

  /// Cancels the latest subscription. A paid term keeps running to its end
  /// date, so access usually survives this call.
  Future<Result<SubscriptionState, AppException>> cancel();
}
