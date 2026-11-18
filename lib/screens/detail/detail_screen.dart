import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../components/page_frame.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import 'detail_frame.dart';
import 'detail_top.dart';
import 'linked_detail.dart';
import 'not_linked_detail.dart';

/// The Detail page. A title route shows that MAL title; an entry route shows
/// the entry's title once it has one, and its page picker until then.
class DetailScreen extends ConsumerWidget {
  const DetailScreen.title(
    int this.malId, {
    super.key,
    this.entryId,
    required this.onBack,
    required this.onOpenTitle,
    required this.onShowPicker,
  });

  const DetailScreen.entry(
    String this.entryId, {
    super.key,
    required this.onBack,
    required this.onOpenTitle,
    required this.onShowPicker,
  }) : malId = null;

  final int? malId;
  final String? entryId;
  final VoidCallback onBack;
  final void Function(int malId, {String? entryId}) onOpenTitle;
  final ValueChanged<String> onShowPicker;

  Widget _linked(int malId) => LinkedDetail(
    // a pick or a rematch can move the entry to another title
    key: ValueKey(malId),
    malId: malId,
    entryId: entryId,
    onBack: onBack,
    onOpenTitle: onOpenTitle,
    onShowPicker: onShowPicker,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final malId = this.malId;
    if (malId != null) return _linked(malId);

    final page = ref.watch(notLinkedPageProvider(entryId!));
    final entry = page.value?.entry;
    if (entry == null) {
      return DetailFrame(
        title: '',
        onBack: onBack,
        top: page.isLoading
            ? const SizedBox.shrink()
            : Padding(
                padding: PageFrame.content.copyWith(top: DetailTop.titleTop),
                child: Text(
                  page.hasError
                      ? 'This entry could not be read.'
                      : 'This entry is no longer on your list.',
                  style: AppText.label(Tokens.inkSoft),
                ),
              ),
      );
    }
    final linkedTo = entry.malId;
    return linkedTo == null
        ? NotLinkedDetail(entry: entry, onBack: onBack)
        : _linked(linkedTo);
  }
}
