import 'package:flutter_mobile_template/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/subscription_entities.dart';

/// Wire models for subscriptions.
///
/// Enums travel BY NAME — the host registers Newtonsoft's `StringEnumConverter`
/// — and each `…FromWire` tolerates an ordinal as a fallback, with the Dart
/// enums declared in the server's order so the fallback is never wrong.
class PlanPriceDto {
  const PlanPriceDto({
    required this.cycle,
    this.price = 0,
    this.currency = 'USD',
    this.durationDays = 30,
  });

  /// Null when the cycle is one this build does not know — the caller drops the
  /// whole price rather than quoting it under the wrong name.
  static PlanPriceDto? tryFromJson(Map<String, dynamic> json) {
    final cycle = cycleFromWire(json['cycle']);
    return cycle == null ? null : PlanPriceDto._(json, cycle);
  }

  factory PlanPriceDto._(Map<String, dynamic> json, BillingCycle cycle) =>
      PlanPriceDto(
        cycle: cycle,
        // numeric(18,2) usually arrives as a JSON number, but some decimal
        // converters emit it as a string. Parsed through text so either shape
        // decodes instead of throwing a TypeError inside the paywall.
        price: _money(json['price']),
        currency: '${json['currency'] ?? 'USD'}',
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      );

  final BillingCycle cycle;
  final double price;
  final String currency;
  final int durationDays;

  PlanPrice toDomain() => PlanPrice(
    cycle: cycle,
    price: price,
    currency: currency,
    durationDays: durationDays,
  );

  /// The server's `BillingCycleEnum` is numbered from ONE — Monthly = 1,
  /// Annual = 2 — so the ordinal fallback maps by hand. Indexing
  /// `BillingCycle.values` would read an annual term as monthly and quote a
  /// year's money as a month's.
  ///
  /// An unrecognised cycle returns NULL rather than falling back to monthly,
  /// the same rule the feature list follows and for a sharper reason: the cycle
  /// this decodes to is the word printed next to a price. A tenant adding a
  /// quarterly option — which the server is built to allow without a migration
  /// — would otherwise have a quarter's money displayed as a month's on every
  /// build shipped before it existed.
  static BillingCycle? cycleFromWire(Object? raw) {
    if (raw is num) {
      return switch (raw.toInt()) {
        1 => BillingCycle.monthly,
        2 => BillingCycle.annual,
        _ => null,
      };
    }
    return switch ('$raw'.toLowerCase()) {
      'monthly' => BillingCycle.monthly,
      'annual' => BillingCycle.annual,
      _ => null,
    };
  }

  /// The wire name for a cycle, for the Start route's segment. Capitalised the
  /// way the server spells the enum member — the route binder is
  /// case-insensitive, but a URL that reads like the contract is one fewer
  /// thing to doubt when a request 404s.
  static String wireName(BillingCycle cycle) => switch (cycle) {
    BillingCycle.monthly => 'Monthly',
    BillingCycle.annual => 'Annual',
  };
}

class SubscriptionPlanDto {
  const SubscriptionPlanDto({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.features = const [],
    this.prices = const [],
  });

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlanDto(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}'.trim(),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        features: featuresFromWire(json['features']),
        prices: pricesFromWire(json['prices']),
      );

  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final List<PlanFeature> features;
  final List<PlanPriceDto> prices;

  SubscriptionPlan toDomain() => SubscriptionPlan(
    id: id,
    name: name,
    description: (description ?? '').isEmpty ? null : description,
    sortOrder: sortOrder,
    features: features,
    prices: prices.map((p) => p.toDomain()).toList(growable: false),
  );

  /// Type-tested, not cast, like the feature list: a TypeError here escapes
  /// apiCall and fails the whole subscription read because one field arrived in
  /// an unexpected shape.
  ///
  /// A cycle appearing twice is collapsed to the first, because every lookup
  /// downstream takes the first match and a duplicate would make which price is
  /// quoted depend on list order.
  static List<PlanPriceDto> pricesFromWire(Object? raw) {
    final items = raw is List ? raw : const [];
    final out = <PlanPriceDto>[];
    final seen = <BillingCycle>{};
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final price = PlanPriceDto.tryFromJson(item);
      if (price == null) continue;
      if (seen.add(price.cycle)) out.add(price);
    }
    return out;
  }

  /// Enums travel by name; an ordinal is tolerated as a fallback. An
  /// unrecognised member is DROPPED rather than defaulted — a new feature the
  /// app has not shipped support for must not silently read as an old one.
  static List<PlanFeature> featuresFromWire(Object? raw) {
    // Type-tested, not cast: a TypeError here escapes apiCall and fails the whole
    // subscription read because one field arrived in an unexpected shape.
    final items = raw is List ? raw : const [];
    final out = <PlanFeature>[];
    for (final item in items) {
      if (item is num) {
        final i = item.toInt();
        if (i >= 0 && i < PlanFeature.values.length) out.add(PlanFeature.values[i]);
        continue;
      }
      final name = '$item'.toLowerCase();
      for (final feature in PlanFeature.values) {
        if (feature.name.toLowerCase() == name) {
          out.add(feature);
          break;
        }
      }
    }
    return out;
  }
}

class PlanChangeQuoteDto {
  const PlanChangeQuoteDto._(this._json);

  factory PlanChangeQuoteDto.fromJson(Map<String, dynamic> json) =>
      PlanChangeQuoteDto._(json);

  final Map<String, dynamic> _json;

  /// Read straight through to the domain object — there is nothing to reshape,
  /// and every figure is the server's.
  PlanChangeQuote toDomain() => PlanChangeQuote(
    planId: '${_json['planId'] ?? ''}',
    planName: '${_json['planName'] ?? ''}',
    cycle: PlanPriceDto.cycleFromWire(_json['cycle']),
    currentPlanName: '${_json['currentPlanName'] ?? ''}',
    currentCycle: PlanPriceDto.cycleFromWire(_json['currentCycle']),
    price: _money(_json['price']),
    currency: '${_json['currency'] ?? 'USD'}',
    durationDays: (_json['durationDays'] as num?)?.toInt() ?? 0,
    remainingDays: (_json['remainingDays'] as num?)?.toInt() ?? 0,
    expiresAt: _json['expiresAt'] == null
        ? null
        : PostDto.parseDate(_json['expiresAt']),
    creditAmount: _money(_json['creditAmount']),
    amountDue: _money(_json['amountDue']),
    isDowngrade: _json['isDowngrade'] == true,
    // Defaults to FALSE when absent, the opposite of hasAccess: a quote the app
    // cannot read must not present itself as a change somebody can confirm.
    allowed: _json['allowed'] == true,
    reason: '${_json['reason'] ?? ''}'.trim().isEmpty
        ? null
        : '${_json['reason']}'.trim(),
  );
}

class SubscriptionDto {
  const SubscriptionDto({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.cancelledAt,
    this.price = 0,
    this.currency = 'USD',
    this.durationDays = 0,
    this.cycle,
    this.creditedValue = 0,
    this.daysRemaining = 0,
    this.isLive = false,
    this.autoRenew = false,
    this.invoiceNumber,
  });

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) =>
      SubscriptionDto(
        id: '${json['id'] ?? ''}',
        planId: '${json['planId'] ?? ''}',
        planName: '${json['planName'] ?? ''}',
        status: statusFromWire(json['status']),
        startedAt: json['startedAt'] == null
            ? null
            : PostDto.parseDate(json['startedAt']),
        expiresAt: json['expiresAt'] == null
            ? null
            : PostDto.parseDate(json['expiresAt']),
        cancelledAt: json['cancelledAt'] == null
            ? null
            : PostDto.parseDate(json['cancelledAt']),
        price: _money(json['price']),
        currency: '${json['currency'] ?? 'USD'}',
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
        cycle: PlanPriceDto.cycleFromWire(json['cycle']),
        creditedValue: _money(json['creditedValue']),
        daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
        isLive: json['isLive'] == true,
        autoRenew: json['autoRenew'] == true,
        invoiceNumber: (json['invoiceNumber'] as num?)?.toInt(),
      );

  final String id;
  final String planId;
  final String planName;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final double price;
  final String currency;
  final int durationDays;
  final BillingCycle? cycle;
  final double creditedValue;
  final int daysRemaining;
  final bool isLive;
  final bool autoRenew;
  final int? invoiceNumber;

  Subscription toDomain() => Subscription(
    id: id,
    planId: planId,
    planName: planName,
    status: status,
    startedAt: startedAt,
    expiresAt: expiresAt,
    cancelledAt: cancelledAt,
    price: price,
    currency: currency,
    durationDays: durationDays,
    cycle: cycle,
    creditedValue: creditedValue,
    daysRemaining: daysRemaining,
    isLive: isLive,
    autoRenew: autoRenew,
    invoiceNumber: invoiceNumber,
  );

  static SubscriptionStatus statusFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < SubscriptionStatus.values.length
          ? SubscriptionStatus.values[i]
          : SubscriptionStatus.pending;
    }
    return switch ('$raw'.toLowerCase()) {
      'active' => SubscriptionStatus.active,
      'expired' => SubscriptionStatus.expired,
      'cancelled' || 'canceled' => SubscriptionStatus.cancelled,
      _ => SubscriptionStatus.pending,
    };
  }
}

/// A `numeric(18,2)` off the wire, whichever shape it took.
double _money(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw') ?? 0;
}

class SubscriptionStateDto {
  const SubscriptionStateDto({
    this.required = false,
    this.hasAccess = true,
    this.source = AccessSource.ungated,
    this.trialEndsAt,
    this.current,
    this.plans = const [],
    this.features = const [],
  });

  factory SubscriptionStateDto.fromJson(Map<String, dynamic> json) {
    final plans = (json['plans'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlanDto.fromJson)
        .toList(growable: false);

    final current = json['current'];

    return SubscriptionStateDto(
      required: json['required'] == true,
      // Defaults to TRUE when absent, deliberately. A response the app cannot
      // read must not lock someone out of a panel they have paid for — the
      // server enforces the gate regardless, so an optimistic client costs
      // nothing worse than a 402 on the next request.
      hasAccess: json['hasAccess'] != false,
      source: sourceFromWire(json['source']),
      trialEndsAt: json['trialEndsAt'] == null
          ? null
          : PostDto.parseDate(json['trialEndsAt']),
      current: current is Map<String, dynamic>
          ? SubscriptionDto.fromJson(current)
          : null,
      plans: plans,
      features: SubscriptionPlanDto.featuresFromWire(json['features']),
    );
  }

  final bool required;
  final bool hasAccess;
  final AccessSource source;
  final DateTime? trialEndsAt;
  final SubscriptionDto? current;
  final List<SubscriptionPlanDto> plans;
  final List<PlanFeature> features;

  SubscriptionState toDomain() => SubscriptionState(
    required: required,
    hasAccess: hasAccess,
    source: source,
    trialEndsAt: trialEndsAt,
    current: current?.toDomain(),
    plans: plans.map((p) => p.toDomain()).toList(growable: false),
    features: features,
  );

  static AccessSource sourceFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < AccessSource.values.length
          ? AccessSource.values[i]
          : AccessSource.none;
    }
    return switch ('$raw'.toLowerCase()) {
      'ungated' => AccessSource.ungated,
      'trial' => AccessSource.trial,
      'subscription' => AccessSource.subscription,
      _ => AccessSource.none,
    };
  }
}
