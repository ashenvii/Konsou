import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../library/title_language.dart';

class ProviderPage {
  const ProviderPage({
    required this.malId,
    required this.name,
    this.mediaType,
    this.startDate,
    this.episodes,
    this.coverUrl,
  });

  final int malId;
  final String name;
  final String? mediaType;
  final String? startDate;
  final int? episodes;
  final String? coverUrl;
}

ProviderPage parseProviderPage(
  Map<String, dynamic> page,
  TitleLanguage language,
) {
  final alternative = page['alternative_titles'];
  final picture = page['main_picture'];
  final episodes = page['num_episodes'];
  return ProviderPage(
    malId: page['id'] as int,
    name:
        orderTitles(
          language,
          romaji: page['title'] as String?,
          english: alternative is Map ? alternative['en'] as String? : null,
          japanese: alternative is Map ? alternative['ja'] as String? : null,
        ).firstOrNull ??
        '',
    mediaType: page['media_type'] as String?,
    startDate: page['start_date'] as String?,
    // mal sends 0 when the count is not known yet
    episodes: episodes is int && episodes > 0 ? episodes : null,
    coverUrl: picture is Map ? picture['medium'] as String? : null,
  );
}

Future<List<ProviderPage>> readSuggestions(
  Databases databases,
  String entryId,
  TitleLanguage language,
) async {
  final details = databases.details;
  final rows =
      await (details.select(details.matchSuggestion)
            ..where((row) => row.entryId.equals(entryId))
            ..orderBy([(row) => OrderingTerm.asc(row.position)]))
          .get();
  return [
    for (final row in rows)
      parseProviderPage(jsonDecode(row.json) as Map<String, dynamic>, language),
  ];
}
