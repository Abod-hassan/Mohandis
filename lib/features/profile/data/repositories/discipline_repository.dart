import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/services/tenant_store.dart';
import 'package:mohandis/features/profile/data/dtos/profile_dto.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

/// One engineering discipline — الاختصاص — on this tenant's list.
class Discipline {
  const Discipline({
    required this.id,
    required this.nameAr,
    this.accountType = AccountType.individual,
    this.nameEn = '',
    this.iconUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Discipline.fromJson(Map<String, dynamic> j) => Discipline(
    id: (j['id'] as num?)?.toInt() ?? 0,
    nameAr: '${j['nameAr'] ?? ''}',
    accountType: ProfileDto.accountTypeFromWire(j['accountType']),
    nameEn: '${j['nameEn'] ?? ''}',
    iconUrl: j['iconUrl'] as String?,
    sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    isActive: j['isActive'] != false,
  );

  final int id;

  /// Which list this row belongs to — engineering branches, trades, machinery.
  final AccountType accountType;

  /// What the app shows. The list is Arabic-first.
  final String nameAr;
  final String nameEn;

  /// The logo, stored host-less like every other upload — resolve it through
  /// `imageUrlResolverProvider` before handing it to `Image.network`.
  final String? iconUrl;

  final int sortOrder;
  final bool isActive;
}

/// `GET /api/social/Disciplines` — readable by anyone, including before
/// sign-in, because the profile step of registration offers the list.
/// Creating and editing is admin-only and answers 403 to everyone else.
class DisciplineRepository {
  DisciplineRepository(this._ref);

  final Ref _ref;

  /// [accountType] picks the list: the engineering branches for an engineer,
  /// the trades for a craftsman, the machinery for its owner. Null asks for
  /// every list, which is what the admin screen wants.
  Future<Result<List<Discipline>, AppException>> all({
    AccountType? accountType,
    bool includeInactive = false,
  }) async {
    const path = EndPoints.disciplines;

    // The list is per tenant, and the server resolves the tenant from the
    // bearer token. Sign-up offers this list before there IS a token, so the
    // header goes on exactly while there is none — the same rule storage-zone,
    // login and sign-up follow. Without it an anonymous read has no tenant in
    // scope and comes back empty rather than failing, which reads as "this
    // deployment has no disciplines".
    Options? options;
    final token = await _ref.read(tokenStorageProvider).readAccessToken();
    if (token == null || token.isEmpty) {
      final tenant = await _ref.read(tenantProvider.notifier).resolve();
      if (tenant != null) options = Options(headers: {'X-Tenant-Id': tenant});
    }

    return apiCall(
      path,
      () => _ref.read(apiClientProvider).dio.get<dynamic>(
        path,
        queryParameters: {
          if (accountType != null)
            'accountType': ProfileDto.accountTypeToWire(accountType),
          if (includeInactive) 'includeInactive': true,
        },
        options: options,
      ),
      (envelope) => envelope.list
          .map(Discipline.fromJson)
          .toList(growable: false),
    );
  }

  Future<Result<Discipline, AppException>> create({
    required String nameAr,
    String nameEn = '',
    AccountType accountType = AccountType.individual,
  }) {
    const path = EndPoints.disciplines;
    return apiCall(
      path,
      () => _ref.read(apiClientProvider).dio.post<dynamic>(
        path,
        data: {
          'nameAr': nameAr,
          'nameEn': nameEn,
          'accountType': ProfileDto.accountTypeToWire(accountType),
        },
      ),
      (envelope) => Discipline.fromJson(envelope.object),
    );
  }

  /// Changes only the named fields. Pass an empty [iconUrl] to clear the logo.
  Future<Result<Discipline, AppException>> update(
    int id, {
    String? nameAr,
    String? nameEn,
    String? iconUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    final path = EndPoints.discipline(id);
    return apiCall(
      path,
      () => _ref.read(apiClientProvider).dio.put<dynamic>(
        path,
        data: {
          if (nameAr != null) 'nameAr': nameAr,
          if (nameEn != null) 'nameEn': nameEn,
          if (iconUrl != null) 'iconUrl': iconUrl,
          if (sortOrder != null) 'sortOrder': sortOrder,
          if (isActive != null) 'isActive': isActive,
        },
      ),
      (envelope) => Discipline.fromJson(envelope.object),
    );
  }
}

final disciplineRepositoryProvider = Provider<DisciplineRepository>(
  DisciplineRepository.new,
);

/// The disciplines on offer, for the picker.
///
/// NOT autoDispose: the list is small, changes about never, and both the setup
/// screen and Edit Profile read it — re-fetching it per visit would be a
/// request to say the same twenty words again.
final disciplinesProvider =
    FutureProvider.family<List<Discipline>, AccountType>((ref, type) async {
  final result =
      await ref.watch(disciplineRepositoryProvider).all(accountType: type);
  return result.when(success: (rows) => rows, failure: (e) => throw e);
});

/// The same list including withdrawn rows — the admin screen, which has to
/// show a switched-off discipline in order to switch it back on.
final allDisciplinesProvider =
    FutureProvider.autoDispose<List<Discipline>>((ref) async {
  final result = await ref
      .watch(disciplineRepositoryProvider)
      .all(includeInactive: true);
  return result.when(success: (rows) => rows, failure: (e) => throw e);
});
