import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/panel/data/repositories/panel_repository_impl.dart';
import 'package:mohandis/features/panel/domain/entities/panel_entities.dart';
import 'package:mohandis/features/panel/domain/repositories/panel_repository.dart';
import 'package:mohandis/features/panel/presentation/notifiers/course_market_notifiers.dart';
import 'package:mohandis/features/panel/presentation/widgets/course_status_pill.dart';
import 'package:mohandis/l10n/l10n.dart';

/// Purchases — the administrator's queue, or one author's earnings.
///
/// One screen for both because the row is the same row and the arithmetic on it
/// is the same arithmetic; only whether the decision buttons appear differs,
/// and that follows from the scope. Two screens would have been two places to
/// get a money format wrong.
class CoursePurchasesScreen extends ConsumerWidget {
  const CoursePurchasesScreen({super.key, this.scope = PurchaseScope.all});

  final PurchaseScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final rows = ref.watch(coursePurchasesProvider(scope));
    final admin = scope == PurchaseScope.all;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        title: admin ? l10n.coursePurchasesTitle : l10n.myCoursesEarnings,
        showBack: true,
      ),
      body: rows.when(
        loading: () => const PeopleListSkeleton(count: 6),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(coursePurchasesProvider(scope)),
        ),
        data: (purchases) => RefreshIndicator(
          onRefresh: () =>
              pullRefresh(ref.refresh(coursePurchasesProvider(scope).future)),
          child: purchases.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: EmptyView(
                        title: admin
                            ? l10n.coursePurchasesTitle
                            : l10n.myCoursesEarnings,
                        message: admin
                            ? l10n.coursePurchasesEmpty
                            : l10n.courseEarningsEmpty,
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(RungSpace.gutter),
                  itemCount: purchases.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: RungSpace.sm),
                    child: _Row(
                      purchase: purchases[i],
                      scope: scope,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.purchase, required this.scope});

  final CoursePurchase purchase;
  final PurchaseScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    final (statusLabel, statusFg, statusBg) = switch (purchase.status) {
      CoursePurchaseStatus.pending => (
        l10n.coursePurchasePending,
        c.amber,
        c.amberSoft,
      ),
      CoursePurchaseStatus.paid => (
        l10n.coursePurchasePaid,
        c.green,
        c.greenSoft,
      ),
      CoursePurchaseStatus.cancelled => (
        l10n.purchaseCancelRequest,
        c.ink3,
        c.surface2,
      ),
    };

    return RungCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  purchase.courseTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RungStatusPill(
                label: statusLabel,
                foreground: statusFg,
                background: statusBg,
                dense: true,
              ),
            ],
          ),
          if (purchase.buyer != null) ...[
            const SizedBox(height: 4),
            Text(
              purchase.buyer!.name,
              style: TextStyle(fontSize: 12.5, color: c.ink3),
            ),
          ],
          const SizedBox(height: RungSpace.xs),

          // All three figures, always — including on the author's own list.
          // "What did it sell for" and "what do I get" are different questions
          // and an author is entitled to both answers without doing the sum.
          _Amount(
            label: l10n.purchaseAmountDue,
            value: courseMoney(purchase.amountDue, purchase.currency),
            strong: true,
          ),
          _Amount(
            label: l10n.purchasePlatformShare,
            value: courseMoney(purchase.platformAmount, purchase.currency),
          ),
          _Amount(
            label: l10n.purchaseAuthorShare,
            value: courseMoney(purchase.authorAmount, purchase.currency),
          ),

          if (purchase.note != null) ...[
            const SizedBox(height: 6),
            Text(
              purchase.note!,
              style: TextStyle(fontSize: 12, height: 1.4, color: c.ink3),
            ),
          ],

          if (scope == PurchaseScope.all &&
              purchase.status == CoursePurchaseStatus.pending) ...[
            const SizedBox(height: RungSpace.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _decide(context, ref, confirm: true),
                    child: Text(l10n.purchaseConfirm),
                  ),
                ),
                const SizedBox(width: RungSpace.xs),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(context, ref, confirm: false),
                    child: Text(
                      l10n.purchaseCancelRequest,
                      style: TextStyle(color: c.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool confirm,
  }) async {
    final note = await _noteFor(context, confirm: confirm);
    if (note == null || !context.mounted) return;

    final repo = ref.read(panelRepositoryProvider);
    final result = confirm
        ? await repo.confirmPurchase(id: purchase.id, note: note)
        : await repo.cancelPurchase(id: purchase.id, note: note);

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(coursePurchasesProvider);
        showRungToast(
          context,
          confirm
              ? context.l10n.purchaseConfirmedToast
              : context.l10n.purchaseCancelledToast,
        );
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  /// The note, or null if the sheet was dismissed.
  ///
  /// An empty string is a real answer — "confirmed, nothing to record" — and is
  /// deliberately distinguishable from a dismissal, which must not act.
  Future<String?> _noteFor(
    BuildContext context, {
    required bool confirm,
  }) async {
    final controller = TextEditingController();
    final l10n = context.l10n;

    final answer = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: sheetContext.rung.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RungRadius.lg),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(RungSpace.gutter),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    confirm
                        ? l10n.purchaseConfirm
                        : l10n.purchaseCancelRequest,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RungSpace.sm),
                  RungField(
                    label: l10n.purchaseNote,
                    controller: controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: RungSpace.md),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(controller.text.trim()),
                    child: Text(
                      confirm
                          ? l10n.purchaseConfirm
                          : l10n.purchaseCancelRequest,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    controller.dispose();
    return answer;
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.ink3)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 14 : 12.5,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong ? c.ink : c.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
