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
      status: EntryStatus.watching,
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
      expect(_typeYear(row()), 'TV · 2023');
    });

    test('a year or a month alone still gives the year', () {
      expect(_typeYear(row(startDate: '2019')), 'TV · 2019');
      expect(_typeYear(row(startDate: '2019-04')), 'TV · 2019');
    });

    test('names for every type MAL gives', () {
      expect(_typeYear(row(mediaType: 'movie', startDate: null)), 'Movie');
      expect(_typeYear(row(mediaType: 'ova', startDate: null)), 'OVA');
      expect(_typeYear(row(mediaType: 'ona', startDate: null)), 'ONA');
      expect(
        _typeYear(row(mediaType: 'tv_special', startDate: null)),
        'TV Special',
      );
      expect(_typeYear(row(mediaType: 'special', startDate: null)), 'Special');
    });

    test('a missing part is left out, and nothing at all is empty', () {
      expect(_typeYear(row(mediaType: null)), '2023');
      expect(_typeYear(row(startDate: null)), 'TV');
      expect(_typeYear(row(mediaType: null, startDate: null)), '');
    });

    test('an unknown type is shown as MAL wrote it, capitalised', () {
      expect(_typeYear(row(mediaType: 'cm', startDate: null)), 'CM');
      expect(_typeYear(row(mediaType: 'music', startDate: null)), 'Music');
    });
  });

  group('progress', () {
    test('watched out of total', () {
      expect(_progress(row()), '4 / 12');
    });

    test('an unknown total is a question mark', () {
      expect(_progress(row(episodes: null)), '4 / ?');
      expect(_progress(row(episodes: 0)), '4 / ?');
      expect(_progress(row(watched: 0, episodes: null)), '0 / ?');
    });
  });

  group('type and when', () {
    test('the type and the year, ? with no date', () {
      expect(formatTypeWhen('tv', '2023-09-29', notAired: false), 'TV · 2023');
      expect(formatTypeWhen('tv', null, notAired: false), 'TV · ?');
      expect(formatTypeWhen(null, '2019', notAired: false), '2019');
    });

    test('a title not aired yet gives its whole date', () {
      expect(
        formatTypeWhen('movie', '2027-01-12', notAired: true),
        'Movie · 12 Jan 2027',
      );
    });
  });

  group('card count', () {
    test('on your list: watched out of the total, ? while it is unknown', () {
      expect(formatCardCount(onList: true, watched: 9, total: 28), '9 / 28');
      expect(formatCardCount(onList: true, watched: 3), '3 / ?');
    });

    test('airing and not on your list: the episodes out so far', () {
      expect(formatCardCount(onList: false, total: 12, aired: 8), 'Ep 8 / 12');
      expect(formatCardCount(onList: false, aired: 8), 'Ep 8 / ?');
    });

    test('otherwise the total, ? when MAL has none', () {
      expect(formatCardCount(onList: false, total: 12), '12 ep');
      expect(formatCardCount(onList: false), '? ep');
    });

    test('on your list, an airing title still shows your progress', () {
      expect(
        formatCardCount(onList: true, watched: 5, total: 12, aired: 8),
        '5 / 12',
      );
    });

    test('a franchise counts seasons', () {
      expect(
        formatCardCount(
          onList: true,
          watched: 4,
          total: 12,
          seasonsDone: 2,
          seasonsTotal: 4,
        ),
        '2 / 4 seasons',
      );
    });
  });

  group('MAL score and when', () {
    test('the score with two decimals, ? when MAL has none', () {
      expect(formatMalScore(9.29), '9.29');
      expect(formatMalScore(8), '8.00');
      expect(formatMalScore(null), '?');
    });

    test('the year, ? when there is no date', () {
      expect(formatCardWhen('2023-09-29', notAired: false), '2023');
      expect(formatCardWhen('2019', notAired: false), '2019');
      expect(formatCardWhen(null, notAired: false), '?');
    });

    test('a title not aired yet gives as much of its date as MAL has', () {
      expect(formatCardWhen('2027-01-12', notAired: true), '12 Jan 2027');
      expect(formatCardWhen('2027-01', notAired: true), 'Jan 2027');
      expect(formatCardWhen(null, notAired: true), '?');
    });
  });

  group('title', () {
    test('the name, or the loading words when there is none', () {
      expect(_title(row()), 'Frieren');
      expect(_title(row(name: '')), 'Loading details');
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

String _typeYear(LibraryRow row) =>
    formatTypeYear(row.mediaType, row.startDate);

String _progress(LibraryRow row) =>
    formatProgress(row.episodesWatched, row.episodes);

String _title(LibraryRow row) => formatTitle(row.name);
