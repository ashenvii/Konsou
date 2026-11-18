import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../components/page_frame.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_entry.dart';
import 'detail_frame.dart';
import 'detail_header.dart';
import 'detail_top.dart';
import 'live_entry_controls.dart';
import 'page_picker.dart';
import 'picker_skeleton.dart';

/// The Detail page of an entry with no MAL page yet: its saved name, a blank
/// cover, its controls, and the page picker where MAL's details would be. Once a page is picked
/// the screen swaps this for the normal page.
class NotLinkedDetail extends ConsumerWidget {
  const NotLinkedDetail({super.key, required this.entry, required this.onBack});

  final TitleEntry entry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = entry.entryId;
    final suggestions =
        ref.watch(notLinkedPageProvider(id)).value?.suggestions ?? const [];
    final search = ref.watch(pickerSearchProvider(id));
    final linking = ref.watch(pageLinkingProvider);
    final looking = ref.watch(
      lookingForPageProvider.select((entries) => entries.contains(id)),
    );
    final name = entry.name ?? '';
    return DetailFrame(
      title: name,
      onBack: onBack,
      status: LiveEntryControls(entry: entry, statusOnly: true),
      children: [
        DetailTop(
          malId: null,
          header: DetailHeader(
            name: name.isEmpty ? 'Untitled entry' : name,
            otherName: 'Not linked to a MyAnimeList page yet',
          ),
          controls: LiveEntryControls(entry: entry),
        ),
        Padding(
          padding: PageFrame.content.copyWith(top: Tokens.space5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Tokens.detailTextWidth,
              ),
              child: looking && suggestions.isEmpty
                  ? const _Looking()
                  : PagePicker(
                      suggestions: suggestions,
                      results: search.results,
                      searching: search.searching,
                      note: _note(search, canSearch: linking != null),
                      onPick: linking == null
                          ? null
                          : (page) => linking.pick(id, page.malId),
                      onNone: linking == null
                          ? null
                          : () => linking.declineAll(id),
                      onSearch: ref
                          .read(pickerSearchProvider(id).notifier)
                          .setQuery,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  static String? _note(PickerSearchState search, {required bool canSearch}) {
    if (search.query.isEmpty) return null;
    if (!canSearch || search.failed) return "Can't reach MyAnimeList.";
    if (search.foundNothing) return 'Nothing found for that.';
    final corrected = search.corrected;
    return corrected == null ? null : 'Showing results for "$corrected"';
  }
}

class _Looking extends StatelessWidget {
  const _Looking();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Looking for the page', style: AppText.label(Tokens.inkSoft)),
        const PickerSkeleton(),
      ],
    );
  }
}
