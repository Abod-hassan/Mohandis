import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/subscription_entities.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../dtos/subscription_dtos.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Result<SubscriptionState, AppException>> state() => apiCall(
    EndPoints.subscription,
    () => _api.dio.get<dynamic>(EndPoints.subscription),
    (envelope) => SubscriptionStateDto.fromJson(envelope.object).toDomain(),
  );

  @override
  Future<Result<SubscriptionState, AppException>> start(
    String planId,
    BillingCycle cycle,
  ) {
    final path = EndPoints.subscriptionStart(
      planId,
      PlanPriceDto.wireName(cycle),
    );
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path),
      (envelope) => SubscriptionStateDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<PlanChangeQuote, AppException>> previewChange(
    String planId,
    BillingCycle cycle,
  ) {
    final path = EndPoints.subscriptionChange(
      planId,
      PlanPriceDto.wireName(cycle),
    );
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(path),
      (envelope) => PlanChangeQuoteDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<SubscriptionState, AppException>> change(
    String planId,
    BillingCycle cycle,
  ) {
    final path = EndPoints.subscriptionChange(
      planId,
      PlanPriceDto.wireName(cycle),
    );
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path),
      (envelope) => SubscriptionStateDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<SubscriptionState, AppException>> setAutoRenew(bool enabled) =>
      apiCall(
        EndPoints.subscriptionAutoRenew,
        () => _api.dio.post<dynamic>(
          EndPoints.subscriptionAutoRenew,
          data: {'enabled': enabled},
        ),
        (envelope) => SubscriptionStateDto.fromJson(envelope.object).toDomain(),
      );

  @override
  Future<Result<SubscriptionState, AppException>> cancel() => apiCall(
    EndPoints.subscriptionCancel,
    () => _api.dio.post<dynamic>(EndPoints.subscriptionCancel),
    (envelope) => SubscriptionStateDto.fromJson(envelope.object).toDomain(),
  );
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepositoryImpl(apiClient: ref.watch(apiClientProvider)),
);
