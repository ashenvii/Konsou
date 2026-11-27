import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/library/quick_search.dart';
import 'package:konsou/library/title_language.dart';

final _now = DateTime.utc(2026, 11, 25, 12);

void main() {
  test('a found title carries MAL\'s score, none where MAL gives none', () {
    final scored = quickRowFromPage(
      {'id': 52991, 'title': 'Sousou no Frieren', 'mean': 9.29},
      TitleLanguage.romaji,
      now: _now,
    );
    final unscored = quickRowFromPage(
      {'id': 61000, 'title': 'Not aired yet'},
      TitleLanguage.romaji,
      now: _now,
    );

    expect(scored.malScore, 9.29);
    expect(unscored.malScore, isNull);
  });

  test('a whole-number score reads as a score', () {
    final row = quickRowFromPage(
      {'id': 1, 'title': 'Round', 'mean': 8},
      TitleLanguage.romaji,
      now: _now,
    );

    expect(row.malScore, 8.0);
  });

  test('a title on the list carries its MAL score', () {
    const entry = LibraryEntry(
      entryId: 'e1',
      name: 'Sousou no Frieren',
      status: EntryStatus.watching,
      episodesWatched: 3,
      addedAt: 1,
      changedAt: 1,
      malId: 52991,
      malScore: 9.29,
    );

    expect(quickRowFromEntry(entry).malScore, 9.29);
  });

  test('a found title counts its episodes, or those out so far', () {
    QuickRow found(Map<String, dynamic> page) => quickRowFromPage(
      {'id': 1, 'title': 'x', ...page},
      TitleLanguage.romaji,
      now: _now,
    );

    expect(found({'num_episodes': 13, 'status': 'finished_airing'}).count, (
      done: null,
      total: '13',
      unit: 'ep',
    ));
    expect(found({'num_episodes': 0}).count, (
      done: null,
      total: '?',
      unit: 'ep',
    ));
    // weekly from 2 Oct 2026: eight are out by 25 Nov
    expect(
      found({
        'num_episodes': 12,
        'status': 'currently_airing',
        'media_type': 'tv',
        'start_date': '2026-10-02',
      }).count,
      (done: '8', total: '12', unit: 'aired'),
    );
  });

  test('a found title gives its type and year, or its whole date', () {
    QuickRow found(Map<String, dynamic> page) => quickRowFromPage(
      {'id': 1, 'title': 'x', ...page},
      TitleLanguage.romaji,
      now: _now,
    );

    expect(
      found({'media_type': 'tv', 'start_date': '2019-01-12'}).line,
      'TV · 2019',
    );
    expect(
      found({
        'media_type': 'movie',
        'start_date': '2027-01-12',
        'status': 'not_yet_aired',
      }).line,
      'Movie · 12 Jan 2027',
    );
  });

  test('a title on the list counts its progress', () {
    const entry = LibraryEntry(
      entryId: 'e1',
      name: 'Frieren',
      status: EntryStatus.watching,
      episodesWatched: 3,
      addedAt: 1,
      changedAt: 1,
      malId: 52991,
      hasDetails: true,
      mediaType: 'tv',
      startDate: '2023-09-29',
    );
    final row = quickRowFromEntry(entry);
    expect(row.count, (done: '3', total: '?', unit: null));
    expect(row.line, 'TV · 2023');
  });
}
