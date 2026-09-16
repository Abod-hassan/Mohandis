import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension L10nX on BuildContext {
  /// Shorthand for the generated string catalogue: `context.l10n.jobsTitle`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
