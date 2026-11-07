import 'package:flutter/widgets.dart';

import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/post.dart';

extension PostVisibilityLabel on PostVisibility {
  /// Byline label ("عام" / "المتابعون" / "خاص").
  String label(BuildContext context) => switch (this) {
        PostVisibility.public => context.l10n.visibilityPublic,
        PostVisibility.followers => context.l10n.visibilityFollowers,
        PostVisibility.private => context.l10n.visibilityPrivate,
      };

  /// Composer audience label ("الجميع" / "المتابعون فقط" / "أنا فقط").
  String audienceLabel(BuildContext context) => switch (this) {
        PostVisibility.public => context.l10n.visibilityEveryoneLabel,
        PostVisibility.followers => context.l10n.visibilityFollowersOnlyLabel,
        PostVisibility.private => context.l10n.visibilityOnlyMeLabel,
      };

  PostVisibility get next => switch (this) {
        PostVisibility.public => PostVisibility.followers,
        PostVisibility.followers => PostVisibility.private,
        PostVisibility.private => PostVisibility.public,
      };
}
