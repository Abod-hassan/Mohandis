/// Base contract for data-layer DTOs.
///
/// Implementations should:
///   - Provide a `factory FooDto.fromJson(Map<String, dynamic> json)`.
///   - Override [toDomain] to return the corresponding entity.
///   - Optionally override [toJson] for write paths.
///
/// DTOs are intentionally separate from domain entities even when they look
/// identical — this keeps wire-format changes from leaking into business code.
abstract class BaseDto<T> {
  const BaseDto();

  T toDomain();

  Map<String, dynamic> toJson() => const {};
}
