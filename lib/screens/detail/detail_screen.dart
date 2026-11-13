import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../app/title_page.dart';
import '../../library/row_labels.dart';

// the page itself is ticket 007d3; until then it shows the title's name
class DetailScreen extends ConsumerWidget {
  const DetailScreen.title(int this.malId, {super.key, this.entryId});

  const DetailScreen.entry(String this.entryId, {super.key}) : malId = null;

  final int? malId;
  final String? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = switch (malId) {
      final malId? =>
        ref
            .watch(detailPageProvider(malId, entryId: entryId))
            .value
            ?.details
            ?.name,
      null => ref.watch(notLinkedPageProvider(entryId!)).value?.entry?.name,
    };
    return TitlePage(titleOrLoading(name ?? ''));
  }
}
