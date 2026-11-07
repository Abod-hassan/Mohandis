import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

/// The public privacy policy — the same page the App Store and Google Play
/// listings point to, so what a person reads in the app is what the stores
/// reviewed.
const String kPrivacyPolicyUrl = 'http://192.248.191.138:8086/privacy.html';

/// The terms of use, including the zero-tolerance rules for abusive content
/// that App Store guideline 1.2 requires an app with user posts to have.
const String kTermsUrl = 'http://192.248.191.138:8086/terms.html';

/// Opens the privacy policy.
Future<void> openPrivacyPolicy(BuildContext context) =>
    _openLegalPage(context, kPrivacyPolicyUrl);

/// Opens the terms of use.
Future<void> openTerms(BuildContext context) =>
    _openLegalPage(context, kTermsUrl);

/// In the in-app browser first (Safari View Controller on iOS, a Custom Tab
/// on Android), so reading it doesn't throw the person out of the app; the
/// system browser if that isn't available. A toast if neither works — a
/// silent no-op on a legal link reads as a broken app.
Future<void> _openLegalPage(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && context.mounted) {
    showRungToast(context, context.l10n.legalLinkFailed, success: false);
  }
}
