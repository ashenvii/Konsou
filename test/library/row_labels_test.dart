import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/library/entry_status.dart';
import 'package:konsou/library/library_row.dart';
import 'package:konsou/library/row_labels.dart';

LibraryRow row({
  String name = 'Frieren',
  int watched = 4,
  int? episodes = 12,
  String? mediaType = 'tv',
  String? startDate = '2023-09-29',
  int? malId = 52991,
  bool hasDetails = true,
  int? seasonsDone,
  int? seasonsTotal,
}) {
  return LibraryRow(
    current: LibraryEntry(
      entryId: 'a',
      name: name,
      status: 'watching',
      episodesWatched: watched,
      addedAt: 0,
      changedAt: 0,
      malId: malId,
      hasDetails: hasDetails,
      episodes: episodes,
      mediaType: mediaType,
      startDate: startDate,
    ),
    entryIds: const ['a'],
    addedAt: 0,
    changedAt: 0,
    seasonsDone: seasonsDone,
    seasonsTotal: seasonsTotal,
  );
}

void main() {
  group('type and year line', () {
    test('type and year', () {
      expect(typeYearLine(row()), 'TV · 2023');
    });

    test('a year or a month alone still gives the year', () {
      expect(typeYearLine(row(startDate: '2019')), 'TV · 2019');
      expect(typeYearLine(row(startDate: '2019-04')), 'TV · 2019');
    });

    test('names for every type MAL gives', () {
      expect(typeYearLine(row(mediaType: 'movie', startDate: null)), 'Movie');
      expect(typeYearLine(row(mediaType: 'ova', startDate: null)), 'OVA');
      expect(typeYearLine(row(mediaType: 'ona', startDate: null)), 'ONA');
      expect(
        typeYearLine(row(mediaType: 'tv_special', startDate: null)),
        'TV Special',
      );
      expect(
        typeYearLine(row(mediaType: 'special', startDate: null)),
        'Special',
      );
    });

    test('a missing part is left out, and nothing at all is empty', () {
      expect(typeYearLine(row(mediaType: null)), '2023');
      expect(typeYearLine(row(startDate: null)), 'TV');
      expect(typeYearLine(row(mediaType: null, startDate: null)), '');
    });

    test('an unknown type is shown as MAL wrote it, capitalised', () {
      expect(typeYearLine(row(mediaType: 'cm', startDate: null)), 'CM');
      expect(typeYearLine(row(mediaType: 'music', startDate: null)), 'Music');
    });
  });

  group('progress', () {
    test('watched out of total', () {
      expect(progressText(row()), '4 / 12');
    });

    test('an unknown total shows only what is watched', () {
      expect(progressText(row(episodes: null)), '4');
      expect(progressText(row(episodes: 0)), '4');
    });

    test('nothing watched and no details yet is empty', () {
      expect(progressText(row(watched: 0, episodes: null)), '');
    });
  });

  group('seasons', () {
    test('only for a franchise with several seasons', () {
      expect(seasonsText(row()), isNull);
      expect(seasonsText(row(seasonsDone: 1, seasonsTotal: 2)), '1/2 seasons');
    });
  });

  group('chip count', () {
    test('episodes without spaces, or seasons for a franchise', () {
      expect(chipCount(row()), '4/12');
      expect(chipCount(row(seasonsDone: 1, seasonsTotal: 2)), '1/2');
      expect(chipCount(row(watched: 0, episodes: null)), '');
    });
  });

  group('title', () {
    test('the name, or the loading words when there is none', () {
      expect(titleText(row()), 'Frieren');
      expect(titleText(row(name: '')), 'Loading details');
    });
  });

  group('status words', () {
    test('one for every status', () {
      expect(EntryStatus.onHold.label, 'On hold');
      expect(EntryStatus.planned.label, 'Planned');
      expect(EntryStatus.notInterested.label, 'Not interested');
      expect({
        for (final s in EntryStatus.values) s.label,
      }, hasLength(EntryStatus.values.length));
    });
  });
}
