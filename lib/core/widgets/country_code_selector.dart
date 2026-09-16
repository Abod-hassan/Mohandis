import 'package:flutter/material.dart';

import '../utils/countries.dart';

/// Compact "flag + dial code" pill designed to sit inside a `TextField`'s
/// `prefixIcon` slot. Tap opens a bottom-sheet picker with a search
/// field and the full [Countries.all] list; on selection the sheet
/// closes and [onChanged] fires with the picked [Country].
///
/// Default value is [Countries.iraq] — override via the [value] arg.
///
/// Usage inside a phone `TextField`:
/// ```dart
/// TextField(
///   textDirection: TextDirection.ltr,
///   decoration: InputDecoration(
///     prefixIcon: CountryCodeSelector(
///       value: _country,
///       onChanged: (c) => setState(() => _country = c),
///     ),
///     prefixIconConstraints: const BoxConstraints(minWidth: 84),
///   ),
/// );
/// ```
class CountryCodeSelector extends StatelessWidget {
  const CountryCodeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Country value;
  final ValueChanged<Country> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.flag,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              value.dialCode,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal picker sheet. Held internal so we can own the search-field
/// state without exposing it to the caller.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});
  final Country selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Country> _results = Countries.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() => _results = Countries.search(q));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      // Lift the sheet above the keyboard so the search field stays
      // visible when the user taps into it.
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'اختر البلد',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو رمز الاتصال',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final c = _results[i];
                        final selected = c == widget.selected;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  c.flag,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    c.nameAr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  c.dialCode,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: selected
                                      ? scheme.primary
                                      : scheme.outlineVariant,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
