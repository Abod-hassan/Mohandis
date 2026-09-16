import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// The dark floating confirmation toast from the design system — a check
/// glyph plus a short message, sitting above the bottom nav.
///
/// Every optimistic action (like, save, repost, connect, apply) confirms
/// through this so feedback is consistent app-wide.
void showRungToast(
  BuildContext context,
  String message, {
  bool success = true,
}) {
  final c = context.rung;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_rounded : Icons.error_outline_rounded,
              size: 18,
              color: success ? c.green : c.red,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: c.surface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: c.ink,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(milliseconds: 2200),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: const RoundedRectangleBorder(borderRadius: RungRadius.mdAll),
      ),
    );
}
