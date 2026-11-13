/// Which title name to show. Stored as the `title_language` setting.
enum TitleLanguage {
  romaji,
  english,
  japanese;

  /// The stored words are the old app's: romaji, english and native.
  static TitleLanguage parse(String? stored) => switch (stored) {
    'english' => english,
    'native' || 'japanese' => japanese,
    _ => romaji,
  };
}

List<String> orderTitles(
  TitleLanguage language, {
  required String? romaji,
  required String? english,
  required String? japanese,
}) {
  final ordered = switch (language) {
    TitleLanguage.romaji => [romaji, english, japanese],
    TitleLanguage.english => [english, romaji, japanese],
    TitleLanguage.japanese => [japanese, romaji, english],
  };
  final names = <String>[];
  for (final name in ordered) {
    if (name != null && name.isNotEmpty && !names.contains(name)) {
      names.add(name);
    }
  }
  return names;
}
