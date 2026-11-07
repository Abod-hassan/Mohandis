import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/core/utils/formatters.dart';

import '../../domain/entities/subscription_entities.dart';
import '../notifiers/subscription_notifier.dart';

/// The paywall, and the "what you hold" screen — one widget, because they are
/// the same page seen from two sides and splitting them would duplicate the
/// plan list.
class SubscriptionView extends ConsumerStatefulWidget {
  const SubscriptionView({super.key, required this.state, this.showLockedCopy = false});

  final SubscriptionState state;

  /// Draws the "this section is for subscribers" header. True when this is
  /// standing in for the panel; false when the user opened it on purpose.
  final bool showLockedCopy;

  @override
  ConsumerState<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends ConsumerState<SubscriptionView> {
  bool _busy = false;

  /// Re-reads the gate while a request is waiting on an admin, so the page
  /// flips to "active" by itself when it is approved. Nothing pushes a
  /// subscription change to the client, so this — plus [_lifecycle] — is how
  /// an approval reaches an open screen.
  Timer? _poll;

  /// Re-reads on returning to the app: the likeliest moment to find an
  /// approval is right after switching back from wherever the payment was
  /// made.
  late final AppLifecycleListener _lifecycle;

  static const _pollEvery = Duration(seconds: 20);

  bool get _waitingOnApproval => widget.state.current?.isPending ?? false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refreshIfWaiting);
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant SubscriptionView old) {
    super.didUpdateWidget(old);
    final was = old.state.current;
    final now = widget.state.current;
    // The request this screen was waiting on has just been approved.
    if (was != null &&
        was.isPending &&
        now != null &&
        now.status == SubscriptionStatus.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showRungToast(context, context.l10n.subscriptionApprovedToast);
        }
      });
    }
    _syncPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _syncPolling() {
    if (_waitingOnApproval) {
      _poll ??= Timer.periodic(_pollEvery, (_) => _refreshIfWaiting());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _refreshIfWaiting() {
    if (!mounted || !_waitingOnApproval || _busy) return;
    // Not while another page covers this one — nobody is looking.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    ref.read(subscriptionProvider.notifier).refresh();
  }

  /// Which cycle the user has TAPPED, if any.
  ///
  /// View state, not server state: it is which column of a price list they are
  /// looking at, and it must survive a refresh of the gate without a round
  /// trip. Deliberately nullable and deliberately not the value the cards are
  /// quoted in — see [_effectiveCycle], which resolves it against what is
  /// actually on offer on every build. A plain field seeded once would go stale
  /// the moment a tenant withdraws the cycle it was seeded with, and leave the
  /// whole paywall quoting a price nothing sells.
  BillingCycle? _picked;

  Future<void> _run(Future<void> Function() action) async {
    // The guard lives here as well as in build, so that a caller which does not
    // go through a disabled control — a deep link, a test, a keyboard shortcut —
    // cannot start a second write whose arrival order would decide the answer.
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan, BillingCycle cycle) =>
      _run(() async {
    final result = await ref
        .read(subscriptionProvider.notifier)
        .start(plan.id, cycle);
    if (!mounted) return;
    result.when(
      success: (_) => showRungToast(context, context.l10n.subscriptionStarted),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  });

  /// Moves a RUNNING term to a different plan or cycle: price it, show the
  /// subscriber what happens to the days they have already paid for, and only
  /// then request it.
  ///
  /// The preview is a round trip the user waits for, deliberately. Working the
  /// credit out on the client would be a second implementation of a money rule,
  /// free to drift from the one that writes the row — and the numbers in this
  /// sheet are the ones somebody decides to spend money on.
  Future<void> _change(SubscriptionPlan plan, BillingCycle cycle) =>
      _run(() async {
    final quote = (await ref
            .read(subscriptionProvider.notifier)
            .previewChange(plan.id, cycle))
        .when<PlanChangeQuote?>(
          success: (q) => q,
          failure: (e) {
            if (mounted) {
              showRungToast(
                context,
                arabicMessageForException(e),
                success: false,
              );
            }
            return null;
          },
        );

    if (quote == null || !mounted) return;

    if (!quote.allowed) {
      showRungToast(
        context,
        quote.reason ?? context.l10n.subscriptionChangeBlocked,
        success: false,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ChangeSheet(quote: quote),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(subscriptionProvider.notifier)
        .change(plan.id, cycle);
    if (!mounted) return;
    result.when(
      success: (_) =>
          showRungToast(context, context.l10n.subscriptionChangeDone),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  });

  Future<void> _setAutoRenew(bool enabled) => _run(() async {
    final result = await ref
        .read(subscriptionProvider.notifier)
        .setAutoRenew(enabled);
    if (!mounted) return;
    result.when(
      success: (_) =>
          showRungToast(context, context.l10n.subscriptionAutoRenewSaved),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  });

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.subscriptionCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.subscriptionKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.subscriptionCancelAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _run(() async {
      final result = await ref.read(subscriptionProvider.notifier).cancel();
      if (!mounted) return;
      result.when(
        success: (_) =>
            showRungToast(context, context.l10n.subscriptionCancelled),
        failure: (e) => showRungToast(
          context,
          arabicMessageForException(e),
          success: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = widget.state;
    final current = state.current;

    // Resolved per build rather than held, so the quoted cycle is always one
    // somebody can actually buy — see [_effectiveCycle].
    // Plans left with no price at all — every cycle they sold is one this app
    // does not (see kSoldBillingCycles) — are dropped rather than drawn as a
    // card reading "غير متاح" with a dead button.
    final plans = [for (final p in state.plans) if (p.prices.isNotEmpty) p];
    final cycles = _cyclesOnOffer(plans);
    final cycle = _effectiveCycle(cycles);

    return RefreshIndicator(
      // Still here for the impatient; a pending request is also re-read on a
      // timer and on app resume — see [_poll].
      onRefresh: () async => ref.read(subscriptionProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          RungSpace.gutter,
          RungSpace.md,
          RungSpace.gutter,
          32,
        ),
        children: [
          if (widget.showLockedCopy) ...[
            Icon(Icons.workspace_premium_outlined, size: 44, color: c.gold),
            const SizedBox(height: RungSpace.sm),
            Text(
              l10n.subscriptionLockedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.subscriptionLockedBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink3),
            ),
            const SizedBox(height: RungSpace.lg),
          ],

          // A trial is the reason the panel is open, so it says so — and says
          // when it stops, which is the only part anyone needs to act on.
          if (state.source == AccessSource.trial) ...[
            _Banner(
              icon: Icons.schedule,
              tint: c.amber,
              background: c.amberSoft,
              // The last day of a trial floors to zero, and "ends in 0 days" is
              // simply wrong about a thing with hours left in it.
              text: state.trialDaysRemaining <= 0
                  ? l10n.subscriptionEndsToday
                  : l10n.subscriptionTrialEndsIn(
                      ArabicNumbers.plain(state.trialDaysRemaining),
                    ),
            ),
            const SizedBox(height: RungSpace.md),
          ],

          if (current != null) ...[
            Text(
              l10n.subscriptionCurrent,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: RungSpace.sm),
            _CurrentCard(
              subscription: current,
              busy: _busy,
              onCancel: _cancel,
            ),

            // Only while a term could still renew. Offering the switch on an
            // expired or cancelled subscription would suggest it could bring
            // one back, which it cannot — that is a purchase, not a setting.
            //
            // Tested on the status, not on isLive: a cancelled term stays live
            // until its date runs out, and the server deliberately refuses to
            // re-arm one (that would undo a cancellation into a charge). Keying
            // off isLive here would draw a switch that answers every tap with a
            // red toast for as long as the term has left to run.
            if (current.status == SubscriptionStatus.active ||
                current.isPending) ...[
              const SizedBox(height: RungSpace.sm),
              RungToggleTile(
                title: l10n.subscriptionAutoRenew,
                subtitle: current.autoRenew
                    ? l10n.subscriptionAutoRenewOn
                    : l10n.subscriptionAutoRenewOff,
                value: current.autoRenew,
                // Disabled, not a no-op, while a write is in flight: the switch
                // reflects server state, and letting it be flipped twice would
                // race two writes whose arrival order decides the answer. Null
                // greys it out and stops the taps; a no-op callback would leave
                // it looking live and silently swallow them.
                onChanged: _busy ? null : _setAutoRenew,
              ),
            ],

            const SizedBox(height: RungSpace.lg),
          ],

          Text(
            l10n.subscriptionChoosePlan,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: RungSpace.sm),

          // Drawn only when there is a choice to make, and it offers exactly the
          // cycles the tenant sells. A tenant selling one cycle would otherwise
          // get a two-option control with one dead half, which reads as a bug
          // rather than as a simpler offer.
          if (cycles.length > 1) ...[
            _CycleToggle(
              cycles: cycles,
              value: cycle,
              // The SMALLEST saving on offer, because the badge sits on the
              // toggle rather than on a card and is therefore a claim about
              // every plan under it. Understating is the safe direction — no
              // plan is advertised a discount it does not actually give.
              savingPercent: _leastAnnualSaving(plans),
              onChanged: _busy ? null : (c) => setState(() => _picked = c),
            ),
            const SizedBox(height: RungSpace.sm),
          ],

          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                l10n.subscriptionPlansEmpty,
                style: TextStyle(fontSize: 13.5, color: c.ink3),
              ),
            )
          else
            for (final plan in plans)
              _PlanCard(
                plan: plan,
                cycle: cycle,
                // Holding a running term turns every card into a CHANGE rather
                // than a purchase: the server refuses a second subscription, so
                // "اشترك" would be a lie, but moving to another plan is exactly
                // what somebody looking at this list wants.
                isChange: current?.isLive ?? false,
                // The one card that is neither. Marked rather than hidden, so
                // the list still explains what they are on and what it opens.
                isCurrent: _isCurrentPlan(current, plan, cycle),
                // A plan that does not sell the selected cycle has no figure to
                // put on the button, and the server would refuse it anyway.
                enabled: !_busy &&
                    plan.priceFor(cycle) != null &&
                    !_isCurrentPlan(current, plan, cycle),
                onSubscribe: () => (current?.isLive ?? false)
                    ? _change(plan, cycle)
                    : _subscribe(plan, cycle),
              ),
        ],
      ),
    );
  }

  /// Whether this card is the plan and cycle the viewer is already running.
  ///
  /// One expression, used for both the badge and the disabled button, so the
  /// two cannot drift apart.
  ///
  /// An UNDECODABLE held cycle — the server named one this build does not know,
  /// so [Subscription.cycle] is null — counts as "this plan", on the tier that
  /// matches. It is not the same cycle, but the screen cannot say which cycle
  /// it is, and inviting somebody to "change" onto a card it cannot describe
  /// their current position on is worse than quietly taking the option away.
  static bool _isCurrentPlan(
    Subscription? current,
    SubscriptionPlan plan,
    BillingCycle cycle,
  ) {
    if (current == null || !current.isLive) return false;
    if (current.planId != plan.id) return false;
    return current.cycle == null || current.cycle == cycle;
  }

  /// Every cycle ANY plan on offer can be bought on, in enum order.
  ///
  /// Unioned across the list rather than taken from one plan, because the
  /// toggle is what makes a plan reachable: keyed on a single plan selling both
  /// cycles, a tenant with one monthly-only tier and one annual-only tier would
  /// get no toggle at all and one of the two tiers would be permanently
  /// unbuyable.
  static List<BillingCycle> _cyclesOnOffer(List<SubscriptionPlan> plans) {
    final seen = <BillingCycle>{};
    for (final plan in plans) {
      for (final price in plan.prices) {
        seen.add(price.cycle);
      }
    }
    return BillingCycle.values
        .where(seen.contains)
        .toList(growable: false);
  }

  /// The cycle the cards are quoted in: what the user tapped, else the term
  /// they already hold, else the shortest one on offer.
  ///
  /// Every candidate is checked against [onOffer] before it is used, which is
  /// the whole point of resolving this per build instead of seeding a field
  /// once. A tenant withdrawing the monthly price would otherwise leave a
  /// returning monthly subscriber pinned to a cycle no plan sells, every card
  /// showing "غير متاح", every button disabled, and — with no toggle, because
  /// only one cycle is now on offer — no way out of the screen at all.
  BillingCycle _effectiveCycle(List<BillingCycle> onOffer) {
    final picked = _picked;
    if (picked != null && onOffer.contains(picked)) return picked;

    // Somebody on an annual plan opening this screen is almost never shopping
    // for a monthly one.
    final held = widget.state.current?.cycle;
    if (held != null && onOffer.contains(held)) return held;

    // Nothing on offer at all: quote the cycle this app sells, so the screen
    // is at least self-consistent while it says there is nothing to buy.
    return onOffer.isEmpty ? kSoldBillingCycles.first : onOffer.first;
  }

  /// The smallest saving among the plans that sell BOTH cycles, or null if any
  /// of them gives none.
  ///
  /// The SMALLEST, not the largest: this number is printed once, above a list,
  /// so it is a claim about every card under it that has an annual price.
  /// Advertising the best plan's 25% over a list where one plan saves 8% would
  /// be a number the screen itself contradicts.
  ///
  /// A plan selling only one cycle is skipped rather than suppressing the
  /// badge: it has no annual term for the claim to be false about, and its card
  /// says so in as many words.
  static int? _leastAnnualSaving(List<SubscriptionPlan> plans) {
    int? worst;
    for (final plan in plans) {
      if (plan.priceFor(BillingCycle.monthly) == null ||
          plan.priceFor(BillingCycle.annual) == null) {
        continue;
      }
      final saving = plan.annualSavingPercent;
      if (saving == null) return null;
      if (worst == null || saving < worst) worst = saving;
    }
    return worst;
  }
}

/// What a plan change costs, shown before the subscriber commits to it.
///
/// Every figure comes off [PlanChangeQuote] — the server's arithmetic, not a
/// second copy of it here. The sheet is built around the one number that
/// decides the answer: what they pay today. The plan-to-plan move and the
/// unchanged end date are context for it, not competing with it.
class _ChangeSheet extends StatelessWidget {
  const _ChangeSheet({required this.quote});

  final PlanChangeQuote quote;

  String _plan(BuildContext context, String name, BillingCycle? cycle) =>
      cycle == null ? name : '$name · ${cycle.label(context)}';

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── The hero: what they pay today ──────────────────────────────
          //
          // On the accent, at the top, before anything else. This is the only
          // figure that decides whether somebody taps confirm, and burying it
          // under a list of rows — as the first version of this sheet did —
          // makes them hunt for it.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            color: c.accent,
            child: Column(
              children: [
                Text(
                  quote.isFree
                      ? l10n.subscriptionChangeNoExtraCost
                      : l10n.subscriptionChangeDue,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (!quote.isFree) ...[
                  const SizedBox(height: 6),
                  // Forced LTR: an Arabic-Indic figure and a Latin ISO code on
                  // one line resolve in the wrong order under RTL, so "100 USD"
                  // renders as "USD 100".
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          ArabicNumbers.count(quote.amountDue),
                          style: const TextStyle(
                            fontSize: 34,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currencySymbol(quote.currency),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── The move itself ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _PlanPill(
                          label: l10n.subscriptionChangeFrom,
                          value: _plan(
                            context,
                            quote.currentPlanName,
                            quote.currentCycle,
                          ),
                          muted: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          // Mirrors under RTL, so it always points from the
                          // old plan toward the new one.
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: c.ink3,
                          textDirection: Directionality.of(context),
                        ),
                      ),
                      Expanded(
                        child: _PlanPill(
                          label: l10n.subscriptionChangeTo,
                          value: _plan(context, quote.planName, quote.cycle),
                          muted: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── How the figure above was reached ───────────────────
                  _MoneyRow(
                    label: l10n.subscriptionChangePlanPrice,
                    amount: quote.price,
                    currency: quote.currency,
                  ),
                  if (quote.hasCredit) ...[
                    const SizedBox(height: 7),
                    _MoneyRow(
                      label: l10n.subscriptionChangeCreditAmount,
                      amount: quote.creditAmount,
                      currency: quote.currency,
                      negative: true,
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: c.line),
                  ),
                  _MoneyRow(
                    label: l10n.subscriptionChangeDue,
                    amount: quote.amountDue,
                    currency: quote.currency,
                    emphasised: true,
                  ),

                  const SizedBox(height: 16),

                  // ── What does NOT change ───────────────────────────────
                  //
                  // The single most likely worry at this moment is "do I lose
                  // the rest of my year", so it is answered plainly rather than
                  // left to be inferred from the absence of a warning.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: c.greenSoft,
                      borderRadius: RungRadius.mdAll,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 17,
                          color: c.green,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            l10n.subscriptionChangeKeepsDate(
                              ArabicNumbers.plain(quote.remainingDays),
                            ),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                              color: c.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Moving DOWN a tier. Said in amber, because everything else
                  // on this sheet is reassuring — the price is lower, the date
                  // is safe — and none of it mentions that the features go at
                  // the moment they confirm.
                  if (quote.isDowngrade) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: c.amberSoft,
                        borderRadius: RungRadius.mdAll,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 17,
                            color: c.amber,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              l10n.subscriptionChangeDowngradeNotice,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                                color: c.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    l10n.subscriptionChangeImmediateNotice,
                    style: TextStyle(fontSize: 11.5, height: 1.5, color: c.ink3),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(
                      l10n.subscriptionChangeDismiss,
                      style: TextStyle(color: c.ink2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(l10n.subscriptionChangeConfirm),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One side of the from → to pair.
class _PlanPill extends StatelessWidget {
  const _PlanPill({
    required this.label,
    required this.value,
    required this.muted,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: muted ? c.surface2 : c.accentSoft,
        borderRadius: RungRadius.mdAll,
        border: Border.all(color: muted ? c.line : c.accentSoft2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: c.ink3)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: muted ? c.ink2 : c.accentInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// A label and a figure, with the currency kept out of the RTL run.
class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.negative = false,
    this.emphasised = false,
  });

  final String label;
  final double amount;
  final String currency;

  /// Draws it as a deduction — a minus sign and the accent colour.
  final bool negative;

  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final color = negative ? c.green : (emphasised ? c.ink : c.ink2);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasised ? 13.5 : 12.5,
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w400,
              color: emphasised ? c.ink : c.ink3,
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '${negative ? '− ' : ''}${ArabicNumbers.count(amount)} ${currencySymbol(currency)}',
            style: TextStyle(
              fontSize: emphasised ? 15 : 13,
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// The شهري / سنوي switch above the plan list.
class _CycleToggle extends StatelessWidget {
  const _CycleToggle({
    required this.cycles,
    required this.value,
    required this.savingPercent,
    required this.onChanged,
  });

  /// Exactly the cycles the tenant sells, in enum order. Not
  /// `BillingCycle.values` — an option nobody can buy is not an option.
  final List<BillingCycle> cycles;

  final BillingCycle value;

  /// Shown beside the annual option. Null draws no badge — see
  /// [SubscriptionPlan.annualSavingPercent] for why an absent saving is never
  /// rendered as zero.
  final int? savingPercent;

  /// Null disables the whole control, the same way a null `onPressed` does
  /// everywhere else on this screen.
  final ValueChanged<BillingCycle>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final cycle in cycles)
            Expanded(
              child: _CycleSegment(
                label: cycle.label(context),
                badge: cycle == BillingCycle.annual && savingPercent != null
                    ? context.l10n.billingSave(
                        ArabicNumbers.plain(savingPercent!),
                      )
                    : null,
                selected: cycle == value,
                onTap: onChanged == null ? null : () => onChanged!(cycle),
              ),
            ),
        ],
      ),
    );
  }
}

class _CycleSegment extends StatelessWidget {
  const _CycleSegment({
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    // White on the accent fill, the same way a selected RungFilterChip and
    // every FilledButton do it. NOT accentInk: that is the accent as INK, a
    // darkened blue meant for accent-coloured text on a light ground, so on the
    // accent itself it is navy on blue and all but unreadable.
    final ink = selected ? Colors.white : c.ink2;

    return Material(
      color: selected ? c.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    // A translucent white scrim on the accent, so the badge
                    // reads as a chip on the selected segment rather than a
                    // second colour fighting it — and the number on top of it
                    // stays white, at full contrast against the blue beneath.
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : c.greenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : c.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.tint,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color tint;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: background,
      borderRadius: RungRadius.mdAll,
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: tint),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({
    required this.subscription,
    required this.busy,
    required this.onCancel,
  });

  final Subscription subscription;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final (String label, Color tint) = switch (subscription.status) {
      SubscriptionStatus.active => (l10n.subscriptionStatusActive, c.green),
      SubscriptionStatus.pending => (l10n.subscriptionStatusPending, c.amber),
      SubscriptionStatus.expired => (l10n.subscriptionStatusExpired, c.ink3),
      SubscriptionStatus.cancelled => (l10n.subscriptionStatusCancelled, c.red),
    };

    // Only for a subscription that is still running. Keyed on isLive rather
    // than on expiresAt being set, or an expired one would read
    // "منتهٍ · ينتهي اليوم" — its expiry date is in the past, not today.
    final String? remaining = !subscription.isLive
        ? null
        : subscription.daysRemaining <= 0
        ? l10n.subscriptionEndsToday
        : l10n.subscriptionExpiresIn(
            ArabicNumbers.plain(subscription.daysRemaining),
          );

    return RungCard(
      radius: RungRadius.md + 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subscription.planName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: tint,
                  ),
                ),
              ),
            ],
          ),
          // Which cycle this term is on, under the tier's name. The two used
          // to be the same fact — the plan WAS the term — and without this the
          // card cannot tell "احترافي شهري" from "احترافي سنوي" at all.
          //
          // Omitted, not guessed, when the server named a cycle this build does
          // not know: a line that silently reads "شهري" on an unrecognised term
          // is worse than no line.
          if (subscription.cycle != null) ...[
            const SizedBox(height: 4),
            Text(
              subscription.cycle!.label(context),
              style: TextStyle(fontSize: 12, color: c.ink3),
            ),
          ],
          if (subscription.isPending) ...[
            const SizedBox(height: 8),
            Text(
              l10n.subscriptionPendingNotice,
              style: TextStyle(fontSize: 12.5, height: 1.5, color: c.ink3),
            ),
          ] else if (remaining != null) ...[
            const SizedBox(height: 6),
            Text(remaining, style: TextStyle(fontSize: 12.5, color: c.ink3)),
          ],
          // Shown only when Finance has actually raised one. Nothing stands in
          // for its absence: a term this deployment has no gateway to bill is
          // not "awaiting an invoice", it is simply not invoiced here.
          if (subscription.invoiceNumber != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 14, color: c.ink3),
                const SizedBox(width: 6),
                Text(
                  l10n.subscriptionInvoiceNumber(
                    ArabicNumbers.plain(subscription.invoiceNumber!),
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ),
          ],
          // Tested on the STATUS, not on isLive — the same distinction the
          // auto-renew switch above makes, and for the same reason. A cancelled
          // term stays live until its date passes, because cancelling stops the
          // renewal rather than confiscating the term somebody paid for. Keyed
          // on isLive this button therefore survives its own press: the card
          // says "ملغى", the button still says "إلغاء الاشتراك", and every tap
          // is answered "Nothing to cancel." by a server that correctly refuses
          // to cancel the same thing twice.
          if (subscription.isPending ||
              subscription.status == SubscriptionStatus.active) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: busy ? null : onCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.subscriptionCancelAction,
                  style: TextStyle(fontSize: 13, color: c.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.isChange,
    required this.isCurrent,
    required this.enabled,
    required this.onSubscribe,
  });

  /// Whether tapping this card MOVES a running term rather than starting one.
  /// Only the wording differs — the sheet that follows explains the rest.
  final bool isChange;

  /// This is the plan and cycle they are already on.
  final bool isCurrent;

  final SubscriptionPlan plan;

  /// Which of the plan's prices to quote. The card shows one figure, not both:
  /// the choice was made once, above the list.
  final BillingCycle cycle;

  final bool enabled;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final price = plan.priceFor(cycle);

    return RungCard(
      margin: const EdgeInsets.only(bottom: 10),
      radius: RungRadius.md + 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.subscriptionCurrentPlanBadge,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: c.accentInk,
                    ),
                  ),
                ),
            ],
          ),
          if ((plan.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              plan.description!,
              style: TextStyle(fontSize: 12.5, height: 1.5, color: c.ink3),
            ),
          ],
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.planIncludes,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: c.ink3,
              ),
            ),
            const SizedBox(height: 6),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 15, color: c.green),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        feature.label(context),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),

          // A tier the tenant does not sell on this cycle. Said plainly rather
          // than hidden: the card still lists what the tier opens, and removing
          // it as the toggle moves would make plans appear and disappear under
          // the user's thumb.
          if (price == null)
            Text(
              l10n.subscriptionCycleUnavailable,
              style: TextStyle(fontSize: 12.5, color: c.ink3),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  // Localised digits, then the ISO code as its own run — a
                  // three-letter Latin code inside an RTL line resolves cleanly
                  // on its own but not when glued to an Arabic-Indic number.
                  ArabicNumbers.count(price.price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    currencySymbol(price.currency),
                    style: TextStyle(fontSize: 12.5, color: c.ink3),
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    cycle.per(context),
                    style: TextStyle(fontSize: 12.5, color: c.ink3),
                  ),
                ),
                const Spacer(),
                // The exact term, because "سنوياً" is the cycle's name and this
                // is the number of days it actually buys — which the tenant
                // sets, and which is the figure the subscription card will
                // count down from.
                Text(
                  l10n.subscriptionPerDays(
                    ArabicNumbers.plain(price.durationDays),
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: enabled ? onSubscribe : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(
              isCurrent
                  ? l10n.subscriptionCurrentPlanBadge
                  : isChange
                  ? l10n.subscriptionChangeAction
                  : l10n.subscriptionSubscribe,
            ),
          ),
        ],
      ),
    );
  }
}
