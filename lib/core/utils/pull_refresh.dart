/// Drives a `RefreshIndicator` from a Riverpod provider.
///
/// Call it with `ref.refresh(someProvider.future)`:
///
/// ```dart
/// onRefresh: () => pullRefresh(ref.refresh(notesProvider.future)),
/// ```
///
/// `RefreshIndicator` holds its spinner up until the future it is handed
/// completes. `onRefresh: () async => ref.invalidate(p)` returns on the same
/// tick, so the spinner snapped shut before the request had even left the
/// device. To a user that reads as "the pull did nothing" — and the natural
/// answer to that is to pull again, and again, which is how one list ended up
/// fetched three times over with nothing on screen to show for it.
///
/// `ref.refresh(p.future)` invalidates AND hands back the new read, so the
/// indicator stays up for exactly as long as the request takes. The list under
/// it keeps its current rows meanwhile: `AsyncValue.when` skips the loading
/// branch on a refresh that has previous data, which is why this does not
/// flash the skeleton on every pull.
///
/// Errors are swallowed deliberately. The provider already holds the failure
/// and the screen's error view is what renders it; rethrowing here would only
/// add an unhandled future error on top of one that is already on screen.
Future<void> pullRefresh(Future<Object?> reload) async {
  try {
    await reload;
  } catch (_) {
    // See above — the provider carries the error.
  }
}
