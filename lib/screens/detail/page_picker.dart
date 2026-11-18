import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_button.dart';
import '../../components/find_field.dart';
import '../../components/hairline.dart';
import '../../components/one_line_text.dart';
import '../../components/text_action.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/provider_page.dart';
import '../../library/row_labels.dart';
import '../../mal/matching.dart' show maxSuggestions;
import 'picker_skeleton.dart';

/// A suggested MAL page: cover, title, type and year, episodes, and Pick.
class _PagePickerRow extends StatelessWidget {
  const _PagePickerRow({required this.page, required this.onPick});

  final ProviderPage page;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final count = page.episodes;
    final episodes = count == null ? '' : episodeCount(count);
    final line = [
      typeYear(page.mediaType, page.startDate),
      episodes,
    ].where((part) => part.isNotEmpty).join(' · ');
    return Container(
      height: Tokens.listRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
      child: Row(
        children: [
          // a suggestion's details are not saved, so the cover fetches them
          CoverView(
            malId: page.malId,
            width: Tokens.listCoverWidth,
            loading: true,
          ),
          const SizedBox(width: Tokens.space3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneLineText(
                  titleOrLoading(page.name),
                  style: AppText.label(Tokens.ink),
                ),
                const SizedBox(height: Tokens.space2),
                OneLineText(line, style: AppText.caption(Tokens.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: Tokens.space3),
          AppButton(
            label: 'Pick',
            kind: ButtonKind.secondary,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}

/// What an entry with no MAL page shows in place of MAL's details: up to five
/// suggestions, "None of these", and a search box.
class PagePicker extends StatelessWidget {
  const PagePicker({
    super.key,
    required this.suggestions,
    required this.onPick,
    required this.onNone,
    required this.onSearch,
    this.results = const [],
    this.searching = false,
    this.note,
  });

  final List<ProviderPage> suggestions;

  /// Null while nothing can be picked: no connection to MAL is set up.
  final ValueChanged<ProviderPage>? onPick;
  final VoidCallback? onNone;
  final ValueChanged<String> onSearch;

  /// What the typed search found; shown under the box.
  final List<ProviderPage> results;
  final bool searching;

  /// A line under the box: nothing found, no connection, a corrected search.
  final String? note;

  Widget _row(ProviderPage page) => _PagePickerRow(
    page: page,
    onPick: onPick == null ? null : () => onPick!(page),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          suggestions.isEmpty
              ? 'No suggestions. Search for the title.'
              : 'Is it one of these?',
          style: AppText.label(Tokens.inkSoft),
        ),
        const SizedBox(height: Tokens.space2),
        for (final page in suggestions.take(maxSuggestions)) ...[
          _row(page),
          const Hairline(),
        ],
        if (suggestions.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: TextAction(label: 'None of these', onPressed: onNone),
            ),
          ),
        const SizedBox(height: Tokens.space3),
        FindField(
          initial: '',
          placeholder: 'Search MyAnimeList',
          width: double.infinity,
          closeWhenEmpty: false,
          autofocus: false,
          onChanged: onSearch,
          onClose: () {},
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: Tokens.space3),
            child: Text(note!, style: AppText.caption(Tokens.inkSoft)),
          ),
        if (searching) const PickerSkeleton(),
        for (final page in results) ...[_row(page), const Hairline()],
      ],
    );
  }
}
