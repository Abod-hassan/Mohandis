import 'package:flutter_test/flutter_test.dart';

import 'package:mohandis/features/posts/domain/repositories/post_repository.dart';
import 'package:mohandis/features/shared/moderation/report_sheet.dart';

void main() {
  test('report targets match the server ReportTargetTypeEnum ordinals', () {
    expect(ReportTarget.post.wire, 0);
    expect(ReportTarget.reel.wire, 1);
    expect(ReportTarget.comment.wire, 2);
    expect(ReportTarget.message.wire, 3);
    expect(ReportTarget.story.wire, 4);
    expect(ReportTarget.profile.wire, 5);
    expect(ReportTarget.reelComment.wire, 6);
  });

  test('report reasons match the server ReportReasonEnum ordinals', () {
    expect(PostReportReason.spam.wire, 0);
    expect(PostReportReason.other.wire, 9);
    expect(
      PostReportReason.values.map((r) => r.wire).toList(),
      List.generate(10, (i) => i),
    );
  });
}
