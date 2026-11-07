/// A poll attached to a post. The post's text is the question.
class Poll {
  const Poll({
    required this.id,
    required this.options,
    required this.endsAt,
    this.totalVotes = 0,
    this.myOptionId,
    this.isClosed = false,
  });

  final String id;
  final List<PollOption> options;
  final int totalVotes;

  /// The option this viewer picked, or null when they have not voted.
  final String? myOptionId;

  final DateTime endsAt;

  /// The server's word on it. [closed] also checks the clock, so a poll that
  /// ran out while the screen was open stops taking taps.
  final bool isClosed;

  bool get closed => isClosed || DateTime.now().isAfter(endsAt);
  bool get voted => myOptionId != null;

  /// Results show once you have voted or voting is over.
  bool get showResults => voted || closed;

  /// 0..1 share of the vote for [option].
  double shareOf(PollOption option) =>
      totalVotes == 0 ? 0 : option.votes / totalVotes;

  /// The vote applied locally, the way the server will apply it: a new vote,
  /// a moved vote, or — the same option again — the vote taken back.
  Poll vote(String optionId) {
    final previous = myOptionId;
    final takeBack = previous == optionId;
    return Poll(
      id: id,
      endsAt: endsAt,
      isClosed: isClosed,
      myOptionId: takeBack ? null : optionId,
      totalVotes: totalVotes + (takeBack ? -1 : (previous == null ? 1 : 0)),
      options: [
        for (final o in options)
          if (o.id == optionId)
            o.withVotes(o.votes + (takeBack ? -1 : 1))
          else if (o.id == previous)
            o.withVotes(o.votes - 1)
          else
            o,
      ],
    );
  }
}

class PollOption {
  const PollOption({required this.id, required this.text, this.votes = 0});

  final String id;
  final String text;
  final int votes;

  PollOption withVotes(int value) =>
      PollOption(id: id, text: text, votes: value < 0 ? 0 : value);
}

/// What the composer sends to attach a poll to a new post: 2–4 choices of up
/// to 80 characters, open for 1–168 hours.
class PollDraft {
  const PollDraft({required this.options, this.durationHours = 24});

  final List<String> options;
  final int durationHours;

  static const int minOptions = 2;
  static const int maxOptions = 4;
  static const int maxOptionLength = 80;

  /// The choices that will actually be sent — trimmed, blanks dropped.
  List<String> get cleaned => [
    for (final o in options)
      if (o.trim().isNotEmpty) o.trim(),
  ];

  /// Enough distinct, non-empty choices to publish.
  bool get isValid {
    final c = cleaned;
    return c.length >= minOptions &&
        c.length <= maxOptions &&
        c.every((o) => o.length <= maxOptionLength) &&
        c.map((o) => o.toLowerCase()).toSet().length == c.length;
  }

  Map<String, dynamic> toJson() => {
    'options': cleaned,
    'durationHours': durationHours,
  };
}
