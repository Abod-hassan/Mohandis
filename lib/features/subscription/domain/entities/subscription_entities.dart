import 'package:flutter/widgets.dart';

import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/core/utils/formatters.dart';

/// Where a subscription is — the backend's `SubscriptionStatusEnum`, in order.
enum SubscriptionStatus { pending, active, expired, cancelled }

/// What is granting access right now — the backend's `AccessSourceEnum`.
///
/// [ungated] is the tenant not charging at all. It is not a kind of
/// subscription and must not be drawn as one: a tenant that has never turned
/// the feature on should see no subscription UI anywhere.
enum AccessSource { none, ungated, trial, subscription }

/// A thing a plan unlocks — the backend's `PlanFeatureEnum`, in order.
///
/// Only content is here. Notes and the assistant are free to everyone, so they
/// deliberately have no member: an entitlement nobody can be without is not an
/// entitlement.
enum PlanFeature {
  theoryCourses,
  practicalCourses,
  trainingCourses,
  library,
  legalAffairs,
}

/// How often a plan is paid for — the backend's `BillingCycleEnum`.
///
/// Note the server numbers these from ONE, not zero, so the ordinal fallback in
/// the DTO maps them by hand rather than indexing [values].
enum BillingCycle { monthly, annual }

/// The cycles this app SELLS, whatever the backend offers.
///
/// The paywall is otherwise driven entirely by the tenant's price rows, which
/// is the right way round — a cycle can be added or withdrawn without a
/// release. This is the deliberate exception: the product is sold annually
/// only, so a monthly price row left in the database (or re-added later) must
/// not put a monthly tab back in front of a customer. Prices for anything not
/// listed here are dropped as the plans are decoded.
///
/// An existing monthly subscription is unaffected: it is read from the
/// subscription itself, not from this list, and still shows its own term.
const Set<BillingCycle> kSoldBillingCycles = {BillingCycle.annual};

/// One way to pay for a plan: a cycle, a price, and the term it buys.
class PlanPrice {
  const PlanPrice({
    required this.cycle,
    this.price = 0,
    this.currency = kCurrencyCode,
    this.durationDays = 30,
  });

  final BillingCycle cycle;
  final double price;
  final String currency;

  /// The exact term. Sent by the server rather than derived from [cycle],
  /// because "annual" is 365 days in most tenants and 360 in some.
  final int durationDays;
}

/// A TIER an engineer can buy — whatever the tenant has named it.
///
/// A plan carries no price of its own: it is a name, a description and a set of
/// features, sold at one price per billing cycle. Monthly and annual are two
/// ways of paying for the same tier, not two tiers.
class SubscriptionPlan extends BaseEntity {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.features = const [],
    this.prices = const [],
  });

  @override
  final String id;

  final String name;
  final String? description;
  final int sortOrder;

  /// What this plan opens. The paywall's whole argument — a price with no list
  /// beside it asks somebody to buy an unnamed thing.
  final List<PlanFeature> features;

  /// What it costs, one entry per cycle the tenant sells.
  ///
  /// Never empty for a plan the server offers — a tier with no sellable cycle
  /// is filtered out server-side, so the card never has to draw a price it
  /// does not have. [priceFor] still returns null, because a tier may well
  /// sell monthly and not annually.
  final List<PlanPrice> prices;

  PlanPrice? priceFor(BillingCycle cycle) {
    for (final price in prices) {
      if (price.cycle == cycle) return price;
    }
    return null;
  }

  /// What the subscriber saves by paying annually, as a whole percent, or null
  /// when there is nothing honest to claim.
  ///
  /// Computed from the two prices the tenant set rather than stored, so the
  /// badge can never disagree with the numbers printed beside it. The
  /// comparison is scaled by the two TERMS, not by a hard twelve: a tenant
  /// whose year is 360 days and whose month is 30 would otherwise be advertised
  /// a saving they are not offering.
  ///
  /// Null — no badge — when either cycle is missing, when either price is zero
  /// (a free tier has no saving to show), and when the annual price is not
  /// actually cheaper. Drawing "وفّر 0%" is worse than drawing nothing.
  int? get annualSavingPercent {
    final monthly = priceFor(BillingCycle.monthly);
    final annual = priceFor(BillingCycle.annual);
    if (monthly == null || annual == null) return null;
    if (monthly.price <= 0 || annual.price <= 0) return null;
    if (monthly.durationDays <= 0 || annual.durationDays <= 0) return null;

    // Two figures in different currencies do not subtract. Currency lives on the
    // price, not the plan, precisely so a tenant CAN bill the two cycles
    // differently — and 900 SAR against 100 USD/month computes a tidy 26%
    // saving that is actually a 20% markup.
    if (monthly.currency != annual.currency) return null;

    // What a year would cost bought a month at a time.
    final atMonthlyRate =
        monthly.price * (annual.durationDays / monthly.durationDays);
    if (atMonthlyRate <= annual.price) return null;

    final percent = ((1 - annual.price / atMonthlyRate) * 100).round();
    return percent <= 0 ? null : percent;
  }
}

/// What moving to a different plan — or a different cycle of the same one —
/// would cost and how long it would run.
///
/// Every number here is computed by the SERVER and simply displayed. A client
/// working out its own credit would be a second implementation of a money rule,
/// free to drift from the one that writes the row — so the confirmation sheet
/// shows these and the change call recomputes them from scratch rather than
/// sending them back.
class PlanChangeQuote {
  const PlanChangeQuote({
    required this.planId,
    required this.planName,
    required this.cycle,
    required this.currentPlanName,
    this.currentCycle,
    this.price = 0,
    this.currency = kCurrencyCode,
    this.durationDays = 0,
    this.remainingDays = 0,
    this.expiresAt,
    this.creditAmount = 0,
    this.amountDue = 0,
    this.isDowngrade = false,
    this.allowed = false,
    this.reason,
  });

  final String planId;
  final String planName;
  final BillingCycle? cycle;

  final String currentPlanName;
  final BillingCycle? currentCycle;

  final double price;
  final String currency;

  /// The term the new plan sells. Shown for context — a change does NOT buy it;
  /// the dates carry over from the term being replaced.
  final int durationDays;

  /// Whole days left — on the current term, and therefore on the new one too.
  final int remainingDays;

  /// When the term ends. Unchanged by the switch; that is the point of it.
  final DateTime? expiresAt;

  /// What the plan being left counts for against the new one's price. Capped at
  /// [price], so moving DOWN a tier is free rather than a negative invoice.
  final double creditAmount;

  /// What is actually paid: [price] − [creditAmount]. Zero on a downgrade and
  /// on a switch between two plans that cost the same.
  final double amountDue;

  /// Whether this move goes DOWN a tier. Allowed and free — and it takes
  /// features away the moment it is confirmed, which is the part the sheet has
  /// to say out loud, because "no extra charge" reads like good news alone.
  final bool isDowngrade;

  final bool allowed;
  final String? reason;

  /// Whether the term being left is worth something against the new plan.
  bool get hasCredit => creditAmount > 0;

  /// Whether this switch costs nothing — a downgrade, or two plans priced the
  /// same. Worth saying outright rather than printing a zero.
  bool get isFree => amountDue <= 0;
}

/// The viewer's own subscription, whatever state it is in.
class Subscription extends BaseEntity {
  const Subscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.cancelledAt,
    this.price = 0,
    this.currency = kCurrencyCode,
    this.durationDays = 0,
    this.cycle,
    this.creditedValue = 0,
    this.daysRemaining = 0,
    this.isLive = false,
    this.autoRenew = false,
    this.invoiceNumber,
  });

  @override
  final String id;

  final String planId;

  /// Snapshotted server-side, so a retired or renamed plan still reads
  /// correctly on a subscription bought before the change.
  final String planName;

  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final double price;
  final String currency;
  final int durationDays;

  /// Which cycle was bought, snapshotted with the price. Also what a renewal
  /// renews into — the cycle is what was agreed to, not the day count behind
  /// it.
  ///
  /// Null when the server named a cycle this build does not know. Dropped
  /// rather than defaulted, for the same reason an unknown feature is: calling
  /// an unrecognised term "شهري" beside its price is a misquote, and a silent
  /// one. The screen omits the line instead.
  final BillingCycle? cycle;

  /// Money credited off this term's price because it replaced one still
  /// running. Zero for a first purchase and for a renewal; what was invoiced is
  /// [price] minus this.
  final double creditedValue;

  /// Computed by the server against its own clock — a device running a day
  /// fast must not tell someone their subscription has expired when the gate
  /// still honours it.
  final int daysRemaining;

  /// Still granting access, as the SERVER decides it — the same test the gate
  /// makes.
  ///
  /// Deriving it here from [daysRemaining] would be wrong at both ends: that
  /// number floors, so a term with four hours left reads as zero and the plan
  /// buttons would light up for a subscription the server still honours and
  /// will refuse to replace. Note a cancelled subscription can be live —
  /// cancelling stops a renewal, it does not confiscate a paid term.
  final bool isLive;

  /// Whether a fresh term starts by itself when this one ends.
  ///
  /// The subscriber's own switch, and a property of the agreement rather than
  /// of the account: a renewal copies it onto the term it creates, so turning
  /// it off once ends the chain. Cancelling forces it off server-side.
  final bool autoRenew;

  /// Finance's invoice id for this term, once the billing sweep has raised it.
  /// Null while it has not, for a free term, and when no invoicing gateway is
  /// wired — the screen shows a number when there is one and says nothing when
  /// there is not, rather than inventing a state the app cannot verify.
  final int? invoiceNumber;

  /// Requested, not yet honoured. Grants nothing.
  bool get isPending => status == SubscriptionStatus.pending;
}

/// Everything the app needs to decide what to draw for the panel.
///
/// Not a [BaseEntity] — it is a snapshot of a situation, not a row.
class SubscriptionState {
  const SubscriptionState({
    this.required = false,
    this.hasAccess = true,
    this.source = AccessSource.ungated,
    this.trialEndsAt,
    this.current,
    this.plans = const [],
    this.features = const [],
  });

  /// Whether this tenant gates the panel at all.
  final bool required;

  /// The answer. True means open the panel.
  final bool hasAccess;

  final AccessSource source;
  final DateTime? trialEndsAt;
  final Subscription? current;
  final List<SubscriptionPlan> plans;

  /// What this viewer currently holds, unioned across every live subscription
  /// — and everything while they are on a trial.
  final List<PlanFeature> features;

  /// Whole days of trial left, floored, never negative.
  ///
  /// Derived on the client because a trial end date does not drift the way a
  /// subscription's does — there is no server-side state to disagree with.
  int get trialDaysRemaining {
    final ends = trialEndsAt;
    if (ends == null) return 0;
    final left = ends.difference(DateTime.now()).inDays;
    return left <= 0 ? 0 : left;
  }

  /// Whether this viewer may open [feature].
  ///
  /// The same question the server answers on every panel route: an ungated
  /// tenant allows everything, and a gated one allows exactly what [features]
  /// lists — which now includes the sections the tenant has opened to
  /// everyone, so a free section reads as allowed without a subscription.
  bool allows(PlanFeature feature) => !required || features.contains(feature);

  /// Whether this viewer may apply for a job.
  ///
  /// Not a [PlanFeature]: the plans sell panel sections, and applying is gated
  /// on holding a subscription AT ALL rather than on any one of them — which
  /// is also the rule `JobService.Apply` enforces with `HasAccessAsync`. An
  /// ungated tenant allows it, a trial allows it, and a section the tenant
  /// gives away does NOT, because that is a free shelf rather than a
  /// subscription.
  bool get canApplyToJobs => !required || hasAccess;

  /// Whether this viewer may open a panel TOOL — the assistant, the notes.
  ///
  /// Same shape as [canApplyToJobs] and for the same reason: the plans sell
  /// named sections, and these are not among them, so the question is "do they
  /// hold a subscription at all" rather than "which one". A trial allows them;
  /// a tenant that does not charge allows them; a free SECTION does not, since
  /// giving away one shelf is not the same as giving away the panel.
  bool get opensPanelTools => !required || hasAccess;

  /// Whether to show subscription UI at all. A tenant that does not charge has
  /// no plans worth rendering and no state worth explaining.
  bool get isVisible => required;
}

/// What each billing cycle is called on screen, and how a price on it reads.
/// Here rather than in a widget so the toggle, the plan card and the "what you
/// hold" card cannot word the same cycle three ways.
extension BillingCycleLabel on BillingCycle {
  String label(BuildContext context) => switch (this) {
    BillingCycle.monthly => context.l10n.billingCycleMonthly,
    BillingCycle.annual => context.l10n.billingCycleAnnual,
  };

  /// "شهرياً" / "سنوياً" — the suffix beside a figure, which is not the same
  /// word as the name of the cycle on a toggle.
  String per(BuildContext context) => switch (this) {
    BillingCycle.monthly => context.l10n.billingPerMonth,
    BillingCycle.annual => context.l10n.billingPerYear,
  };
}

/// What each entitlement is called on screen. Here rather than in a widget so
/// the paywall and a locked course page cannot word the same feature two ways.
extension PlanFeatureLabel on PlanFeature {
  String label(BuildContext context) => switch (this) {
    PlanFeature.theoryCourses => context.l10n.featureTheoryCourses,
    PlanFeature.practicalCourses => context.l10n.featurePracticalCourses,
    PlanFeature.trainingCourses => context.l10n.featureTrainingCourses,
    PlanFeature.library => context.l10n.featureLibrary,
    PlanFeature.legalAffairs => context.l10n.featureLegalAffairs,
  };
}
