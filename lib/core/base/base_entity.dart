/// Base class for domain entities. Provides `id`-based equality so two
/// instances referencing the same business object compare equal even if other
/// fields have been edited locally.
///
/// Entities should still be immutable — extend this class and add `final`
/// fields plus a `copyWith` method per entity.
abstract class BaseEntity {
  const BaseEntity();

  String get id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}
