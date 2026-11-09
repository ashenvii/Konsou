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
