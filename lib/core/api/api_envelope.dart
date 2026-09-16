import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../error/result.dart';

/// Decoder for the RoboByte backend's response envelope.
///
/// Every module endpoint returns `ResultViewModel<T>` (RoboByte.Kernel), so a
/// 200 body is never the payload itself — it is always:
///
/// ```json
/// { "data": ..., "error": false, "message": "Success",
///   "totalCount": 128, "hasMore": true, "className": null, "extraData": null }
/// ```
///
/// `data` is the payload: an object for single-item actions, an array for
/// paged reads (`IPagedList<T>` serialises as a bare array — the paging
/// metadata rides on `totalCount` / `hasMore`, NOT inside `data`).
///
/// **`error: true` can arrive on a 200.** Services catch their own exceptions
/// and hand back `new ResultViewModel<T>(ex.Message, true)`; controllers then
/// map that to `BadRequest(result)`, but the same envelope also comes back
/// with a 200 on paths that don't. So the flag is checked on every response,
/// not just on failures — see [ApiEnvelope.error].
///
/// **Key casing is normalised on the way in.** The host serialises with
/// Newtonsoft (`AddNewtonsoftJson`), whose contract resolver decides whether
/// properties come back as `authorName` or `AuthorName` — a host-side setting
/// no client should be coupled to. Every key in the envelope and its payload
/// is lower-camelised once, here, so the DTOs can read one spelling and a
/// change to the host's JSON config can never silently decode every field to
/// its default.
class ApiEnvelope {
  const ApiEnvelope({
    required this.error,
    required this.message,
    required this.data,
    this.totalCount,
    this.hasMore = false,
  });

  factory ApiEnvelope.from(Object? body) {
    final normalised = normaliseKeys(body);
    // Not an envelope at all — a bare payload from an endpoint outside the
    // module convention. The Auth module answers this way: `LoginResultDto` as
    // a plain object, register as a plain string. Treat the whole body as the
    // data.
    //
    // `error` is the marker: `ResultViewModel` always serialises it (the host
    // sets no NullValueHandling, so every property is written), and no payload
    // DTO in the platform has a field by that name.
    if (normalised is! Map<String, dynamic> ||
        !normalised.containsKey('error')) {
      return ApiEnvelope(error: false, message: '', data: normalised);
    }
    return ApiEnvelope(
      error: normalised['error'] == true,
      message: '${normalised['message'] ?? ''}',
      data: normalised['data'],
      totalCount: (normalised['totalCount'] as num?)?.toInt(),
      hasMore: normalised['hasMore'] == true,
    );
  }

  final bool error;
  final String message;
  final Object? data;

  /// Total rows matching the filter across all pages — `IPagedList.TotalItemCount`.
  final int? totalCount;

  /// Whether a further page exists — `IPagedList.HasNextPage`.
  final bool hasMore;

  /// [data] as an object, or an empty map when the payload was null or a list.
  Map<String, dynamic> get object =>
      data is Map ? (data! as Map).cast<String, dynamic>() : const {};

  /// [data] as a list of JSON objects. Tolerates a single object by wrapping
  /// it, so `GET /{id}`-style endpoints that return one row still decode.
  List<Map<String, dynamic>> get list {
    final raw = data;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
    }
    if (raw is Map) return [raw.cast<String, dynamic>()];
    return const [];
  }

  /// The failure this envelope describes. Uses the server's own message —
  /// these are written for humans ("Parent comment not found.").
  AppException get exception => ServerException(
    message.isEmpty ? 'The server rejected the request' : message,
  );

  /// Recursively lower-camelises every map key: `AuthorName` → `authorName`,
  /// `Id` → `id`. Already-camel keys pass through untouched, so this is safe to
  /// run whatever the host is configured to emit.
  ///
  /// Only the first character is lowered — `authorAvatarUrl` must not become
  /// `authoravatarurl`, and an all-caps acronym key like `NID` deliberately
  /// becomes `nID`, matching how a camelCase resolver would render it.
  static Object? normaliseKeys(Object? value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          _lowerFirst('${entry.key}'): normaliseKeys(entry.value),
      };
    }
    if (value is List) {
      return value.map(normaliseKeys).toList(growable: false);
    }
    return value;
  }

  static String _lowerFirst(String key) {
    if (key.isEmpty) return key;
    final first = key[0];
    final lowered = first.toLowerCase();
    return first == lowered ? key : '$lowered${key.substring(1)}';
  }
}

/// Runs one API call and decodes its envelope into a [Result].
///
/// Collapses the try/catch every repository method would otherwise repeat:
/// transport failures arrive already mapped to `AppException` by
/// `ErrorMappingInterceptor`, `error: true` becomes a [ServerException]
/// carrying the server's message, and a decode failure becomes an
/// [UnknownException] naming the path instead of a raw cast error.
Future<Result<T, AppException>> apiCall<T>(
  String path,
  Future<Response<dynamic>> Function() send,
  T Function(ApiEnvelope envelope) decode,
) async {
  try {
    final res = await send();
    final envelope = ApiEnvelope.from(res.data);
    if (envelope.error) return Result.failure(envelope.exception);
    return Result.success(decode(envelope));
  } on DioException catch (e) {
    return Result.failure(apiException(e, path));
  } on AppException catch (e) {
    // A decoder can raise a typed failure of its own — e.g. "the envelope
    // parsed fine but the list was empty" — and it should reach the caller
    // as-is rather than being buried in an UnknownException.
    return Result.failure(e);
  } catch (e, s) {
    return Result.failure(
      UnknownException(
        'Could not read the response from $path',
        cause: e,
        stackTrace: s,
      ),
    );
  }
}

/// Maps a [DioException] to an [AppException], preferring the envelope's own
/// `message` over Dio's generic status text.
///
/// `ErrorMappingInterceptor` has already mapped by status code; this only
/// upgrades the message when the error body turned out to be an envelope.
AppException apiException(DioException e, String path) {
  final body = e.response?.data;

  // Auth's failures are bare strings — `BadRequest(user.Message)` — and they
  // carry the only useful text there is ("Passwords must have at least one
  // digit ('0'-'9')."). Losing it for a generic "request failed" would leave
  // someone staring at a rejected form with no idea why.
  if (body is String && body.trim().isNotEmpty) {
    final status = e.response?.statusCode;
    return switch (status) {
      401 || 403 => UnauthorizedException(body),
      402 => PaymentRequiredException(body),
      404 => NotFoundException(body),
      _ => ValidationException(body),
    };
  }

  if (body is Map) {
    final envelope = ApiEnvelope.from(body);
    // `{ "message": "Invalid username" }` — Auth's 401 shape. Not an envelope,
    // so it has no error flag; the whole body lands in `data`, and `object`
    // reads it back.
    final plainMessage = '${envelope.object['message'] ?? ''}';
    if (!envelope.error && plainMessage.isNotEmpty) {
      final status = e.response?.statusCode;
      return switch (status) {
        401 || 403 => UnauthorizedException(plainMessage),
        402 => PaymentRequiredException(plainMessage),
        404 => NotFoundException(plainMessage),
        _ => ServerException(plainMessage, statusCode: status),
      };
    }
    if (envelope.error && envelope.message.isNotEmpty) {
      final mapped = e.error;
      // Keep the interceptor's subtype (Unauthorized / NotFound / …) so
      // presentation still switches on it — only the text is replaced.
      return switch (mapped) {
        UnauthorizedException() => UnauthorizedException(envelope.message),
        ForbiddenException() => ForbiddenException(envelope.message),
        PaymentRequiredException() => PaymentRequiredException(
          envelope.message,
        ),
        NotFoundException() => NotFoundException(envelope.message),
        ValidationException(fieldErrors: final f) => ValidationException(
          envelope.message,
          fieldErrors: f,
        ),
        _ => ServerException(
          envelope.message,
          statusCode: e.response?.statusCode,
        ),
      };
    }
  }
  final mapped = e.error;
  if (mapped is AppException) return mapped;
  final status = e.response?.statusCode;
  return UnknownException(
    'Request failed [${e.type.name}${status != null ? ' · $status' : ''}] $path',
    cause: e,
  );
}
