import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_envelope.dart';
import '../api/endpoints.dart';
import '../providers.dart';

/// The tenant this install writes under, read from the host's `/health`.
///
/// **Only needed before there is a session.** Once signed in, the JWT carries a
/// `TenantId` claim and the server resolves the tenant from that — so this is
/// stamped on the anonymous calls (sign-up, login) and nowhere else. Sending it
/// on authenticated requests would put a client-supplied value in front of the
/// claim, which is precisely the "client-supplied TenantId overriding tenant
/// stamping" the Kernel warns about when it rejects a mis-scoped write.
///
/// Held in memory for the session rather than persisted: it is a property of
/// the deployment the app is pointed at, and a stale value written to disk
/// would outlive a change of `apiBaseUrl`.
class TenantNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  Future<int?>? _inFlight;

  /// The tenant to stamp, fetching it if this is the first ask.
  ///
  /// **Awaited by the auth calls, not merely warmed up by the screen.** A
  /// best-effort warm-up loses the race whenever the lookup is slow, the
  /// screen was hot-reloaded (so `initState` never re-ran), or the person
  /// submits quickly — and the request then goes out with no tenant, which the
  /// server rejects with "No tenant in scope while persisting ContactModel".
  /// Making it a precondition costs one round-trip, once per session.
  ///
  /// Concurrent callers share the in-flight request.
  Future<int?> resolve() {
    final known = state;
    if (known != null) return Future<int?>.value(known);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  /// Fire-and-forget warm-up for the auth screen, so the value is usually
  /// already there by the time anyone submits.
  Future<void> ensureLoaded() => resolve();

  Future<int?> _load() async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .dio
          .get<dynamic>(EndPoints.health);

      // `/health` is a minimal-API endpoint, so it serialises with
      // System.Text.Json rather than the Newtonsoft settings the controllers
      // use — normalise the casing rather than depend on which one answered.
      final body = ApiEnvelope.normaliseKeys(res.data);
      final tenantId = body is Map ? body['tenantId'] : null;

      if (tenantId is num) {
        state = tenantId.toInt();
        return state;
      }

      // Reachable host, but an older build whose /health predates the field.
      debugPrint('[tenant] /health carried no tenantId — using the fallback');
    } catch (e) {
      debugPrint('[tenant] /health lookup failed: $e');
    }

    // Deliberate fallback rather than null: without a tenant the server
    // refuses to write a contact at all, so a wrong-but-plausible id fails
    // more usefully than no id — and against an unreachable host the request
    // that follows was going to fail anyway.
    state = ref.read(appConfigProvider).defaultTenantId;
    return state;
  }
}

final tenantProvider = NotifierProvider<TenantNotifier, int?>(
  TenantNotifier.new,
);
