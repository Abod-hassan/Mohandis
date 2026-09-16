import 'package:flutter/material.dart';

import '../utils/error_messages.dart';

/// Standard error-state widget. Text runs through [arabicMessageForException]
/// so users see friendly Arabic copy for every known backend / transport
/// error — no more `"invalid_otp"` or English Identity messages leaking
/// into the UI.
///
/// Anything unmapped falls back to a generic "حدث خطأ غير متوقع" line so
/// customers never see a stack trace, but the original message stays on
/// the `AppException.cause` for debugging.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              arabicMessageForException(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Cairo',
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
