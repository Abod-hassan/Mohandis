import 'package:flutter_test/flutter_test.dart';

import 'package:mohandis/features/posts/data/dtos/post_dto.dart';
import 'package:mohandis/features/posts/domain/entities/post.dart';

void main() {
  final poll = Poll(
    id: 'p',
    endsAt: DateTime.now().add(const Duration(hours: 5)),
    totalVotes: 3,
    options: const [
      PollOption(id: 'a', text: 'A', votes: 2),
      PollOption(id: 'b', text: 'B', votes: 1),
    ],
  );

  int votesOf(Poll p, String id) => p.options.firstWhere((o) => o.id == id).votes;

  test('a first vote adds one', () {
    final next = poll.vote('b');
    expect(next.myOptionId, 'b');
    expect(next.totalVotes, 4);
    expect(votesOf(next, 'b'), 2);
    expect(next.showResults, isTrue);
  });

  test('voting another option moves the vote', () {
    final next = poll.vote('a').vote('b');
    expect(next.myOptionId, 'b');
    expect(next.totalVotes, 4);
    expect(votesOf(next, 'a'), 2);
    expect(votesOf(next, 'b'), 2);
  });

  test('the same option again takes the vote back', () {
    final next = poll.vote('a').vote('a');
    expect(next.myOptionId, isNull);
    expect(next.totalVotes, 3);
    expect(votesOf(next, 'a'), 2);
  });

  test('a draft needs 2-4 distinct non-empty choices', () {
    expect(const PollDraft(options: ['نعم', '']).isValid, isFalse);
    expect(const PollDraft(options: ['نعم', 'لا']).isValid, isTrue);
    expect(const PollDraft(options: ['Yes', 'yes']).isValid, isFalse);
    expect(const PollDraft(options: ['1', '2', '3', '4', '5']).isValid, isFalse);
    expect(
      const PollDraft(options: [' a ', 'b'], durationHours: 6).toJson(),
      {'options': ['a', 'b'], 'durationHours': 6},
    );
  });

  test('pollFrom reads PollDto', () {
    final parsed = PostDto.pollFrom({
      'id': 'x',
      'options': [
        {'id': 'o1', 'text': 'One', 'votes': 4},
        {'id': 'o2', 'text': 'Two', 'votes': 0},
      ],
      'totalVotes': 4,
      'myOptionId': null,
      'endsAt': '2030-01-01T00:00:00Z',
      'isClosed': false,
    });
    expect(parsed, isNotNull);
    expect(parsed!.options.length, 2);
    expect(parsed.voted, isFalse);
    expect(parsed.totalVotes, 4);
    expect(PostDto.pollFrom(null), isNull);
  });
}
