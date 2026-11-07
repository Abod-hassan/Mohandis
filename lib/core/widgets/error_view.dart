import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/session_expiry.dart';
import '../error/app_exception.dart';
import '../theme/rung_colors.dart';
import '../utils/error_messages.dart';

/// Standard error-state widget. Text runs through [arabicMessageForException]
/// so users see friendly Arabic copy for every known backend / transport
/// error — no more `"invalid_otp"` or English Identity messages leaking
/// into the UI.
///
/// Anything unmapped falls back to a generic "حدث خطأ غير متوقع" line so
/// customers never see a stack trace, but the original message stays on
/// the `AppException.cause` for debugging.
class ErrorView extends ConsumerWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // An expired session is on its way to the login screen, and the errors
    // behind it are the wreckage of that, not something the person can act on.
    // Every screen in the shell fails at once when a token dies, so without
    // this they get a wall of "something went wrong" — each with a retry
    // button that can only fail the same way — for the moment it takes the
    // router to redirect. The notice is cleared by the auth screen once it has
    // said what happened, so this is a window, not a state.
    if (ref.watch(sessionExpiryProvider).noticePending) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

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
              // No `fontFamily` here: AppTheme sets it from RungType.family on
              // every style it builds, and re-declaring it locally is how a
              // screen ends up on a different face when the family changes.
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            // DEBUG ONLY. `arabicMessageForException` is a deliberate one-way
            // door — it exists so customers never see `invalid_otp` or a raw
            // Identity string — but that also means a screenshot of an error
            // says nothing about what actually failed, and the mapper itself
            // can mislabel things. Stripped from release builds by kDebugMode,
            // so this never reaches a customer.
            //
            // Selectable so the text can be copied out of the simulator
            // rather than retyped from a photo of the screen.
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              // Boxed and scrollable. A server stack trace is thousands of
              // pixels tall — it pushed the retry button off the screen and
              // painted the overflow stripes over the page.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _debugDetail(error),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: context.rung.ink3,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// How many lines of it to show: a .NET stack trace arrives as hundreds,
  /// and the first few are the only ones that say what failed.
  static const int _debugLines = 12;

  /// The untranslated truth: exception type, status code where there is one,
  /// and the raw message the mapper was given.
  static String _debugDetail(Object e) {
    if (e is! AppException) return _clip(e.toString());
    final status = e is ServerException && e.statusCode != null
        ? ' [${e.statusCode}]'
        : '';
    final cause = e.cause;
    return _clip(
      '${e.runtimeType}$status\n${e.message}'
      '${cause == null ? '' : '\n— $cause'}',
    );
  }

  static String _clip(String text) {
    final lines = text.split('\n');
    if (lines.length <= _debugLines) return text;
    return '${lines.take(_debugLines).join('\n')}\n… (+${lines.length - _debugLines})';
  }
}
