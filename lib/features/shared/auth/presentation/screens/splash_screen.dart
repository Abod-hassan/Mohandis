import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/services/storage_zone.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../notifiers/auth_notifier.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';

/// Cold-start splash. Blocks navigation on:
///   1. `authNotifierProvider` resolving (either a live session or a
///      definitive signed-out).
///   2. A minimum display window so the splash isn't a flash.
///
/// Signing-bootstrap fires in parallel with the splash animation, best-
/// effort — a failure is swallowed since `RequestSigningInterceptor`
/// gracefully skips signing when no secret is stored.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minDisplay = Duration(milliseconds: 1200);

  Timer? _minTimer;
  bool _minElapsed = false;

  @override
  void initState() {
    super.initState();
    _minTimer = Timer(_minDisplay, () {
      if (!mounted) return;
      setState(() => _minElapsed = true);
      _tryAdvance();
    });
    _bootstrapSigning();
  }

  Future<void> _bootstrapSigning() async {
    try {
      await ref.read(authRepositoryProvider).ensureSigningSecret();
    } catch (_) {
      // Best-effort — swallow.
    }
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    super.dispose();
  }

  void _tryAdvance() {
    if (!_minElapsed) return;
    final auth = ref.read(authNotifierProvider);
    if (auth.isLoading) return;
    final hasSession = auth.maybeWhen(
      data: (s) => s != null,
      orElse: () => false,
    );
    if (!mounted) return;

    // Fetch the CDN zone on the way out of the splash.
    //
    // `storageZoneProvider` is lazy, and nothing used to read it until a screen
    // offered a photo control — but `imageUrlResolverProvider` watches it too.
    // So on a cold start every avatar and every post image resolved through the
    // `AppConfig.cdnBaseUrl` fallback (or through nothing at all, on a
    // deployment with no compiled-in fallback) until somebody happened to open
    // the composer.
    //
    // Here rather than in `initState` because the read sends a bearer when
    // there is one and a resolved tenant header when there is not — and at this
    // point the session has settled, so it picks the right one instead of
    // caching a pre-login answer for the whole run. Not awaited: an image host
    // is not worth holding the app at a logo for, and a failure needs no
    // handling — the notifier records its own "no usable zone" and the resolver
    // keeps its fallback.
    ref.read(storageZoneProvider);

    context.go(hasSession ? '/feed' : '/auth');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (_, __) => _tryAdvance());
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: RungGradients.brand),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RungAppLogo(size: 96),
              const SizedBox(height: 18),
              Text(
                context.l10n.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
