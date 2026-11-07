import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/services/tenant_store.dart';

/// One governorate — المحافظة — on this tenant's list.
class Governorate {
  const Governorate({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Governorate.fromJson(Map<String, dynamic> j) => Governorate(
    id: (j['id'] as num?)?.toInt() ?? 0,
    nameAr: '${j['nameAr'] ?? ''}',
    nameEn: '${j['nameEn'] ?? ''}',
    sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    isActive: j['isActive'] != false,
  );

  final int id;

  /// What the app shows. The list is Arabic-first.
  final String nameAr;
  final String nameEn;
  final int sortOrder;
  final bool isActive;
}

/// `GET /api/social/Governorates` — readable by anyone, including before
/// sign-in, because the profile step of registration offers the list.
class GovernorateRepository {
  GovernorateRepository(this._ref);

  final Ref _ref;

  Future<Result<List<Governorate>, AppException>> all() async {
    const path = EndPoints.governorates;

    // The list is per tenant and the server reads the tenant from the bearer
    // token; sign-up offers it before there IS one, so the header goes on
    // exactly while there is none — the same rule storage-zone and the
    // disciplines list follow.
    Options? options;
    final token = await _ref.read(tokenStorageProvider).readAccessToken();
    if (token == null || token.isEmpty) {
      final tenant = await _ref.read(tenantProvider.notifier).resolve();
      if (tenant != null) options = Options(headers: {'X-Tenant-Id': tenant});
    }

    return apiCall(
      path,
      () => _ref
          .read(apiClientProvider)
          .dio
          .get<dynamic>(path, options: options),
      (envelope) =>
          envelope.list.map(Governorate.fromJson).toList(growable: false),
    );
  }
}

final governorateRepositoryProvider = Provider<GovernorateRepository>(
  GovernorateRepository.new,
);

/// The governorates on offer, for the picker.
///
/// NOT autoDispose, like the disciplines: eighteen rows that change about
/// never, read by both the setup screen and Edit Profile.
final governoratesProvider = FutureProvider<List<Governorate>>((ref) async {
  final result = await ref.watch(governorateRepositoryProvider).all();
  return result.when(success: (rows) => rows, failure: (e) => throw e);
});
