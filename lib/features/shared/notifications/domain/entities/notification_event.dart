/// Typed notification payloads. Extend this sealed family when adding new
/// notification kinds — the presentation layer pattern-matches on subtype.
sealed class NotificationEvent {
  const NotificationEvent({required this.id, required this.receivedAt});

  final String id;
  final DateTime receivedAt;
}

class UnknownNotificationEvent extends NotificationEvent {
  const UnknownNotificationEvent({
    required super.id,
    required super.receivedAt,
    required this.data,
  });

  final Map<String, String> data;
}
