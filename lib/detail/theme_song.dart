/// An opening or ending song, read out of the line MAL writes for it:
/// '#01: "We Are! (ウィーアー!)" by Hiroshi Kitadani (きただにひろし) (eps 1-47)'.
/// A line that does not read that way keeps its whole text as the [name].
class ThemeSong {
  const ThemeSong({
    required this.number,
    required this.name,
    this.nativeName,
    this.artist,
    this.episodes,
  });

  /// Its place in MAL's list: "1", "2", or "S1" for a special's song.
  final String number;
  final String name;

  /// The name in Japanese, when MAL gives it in brackets after the name.
  final String? nativeName;
  final String? artist;

  /// Where it plays, as MAL writes it: "eps 1-16", "ep 28".
  final String? episodes;

  factory ThemeSong.parse(String text, {required int place}) {
    final line = text.trim();
    final match = _line.firstMatch(line);
    if (match == null) return ThemeSong(number: '$place', name: line);
    final number = match.group(1);
    final (name, nativeName) = _splitNative(match.group(2)!.trim());
    final (artist, _) = _splitNative(match.group(3)!.trim());
    return ThemeSong(
      number: number == null ? '$place' : _trimZeros(number),
      name: name,
      nativeName: nativeName,
      artist: artist,
      episodes: match.group(4)?.trim(),
    );
  }

  static final _line = RegExp(
    r'^(?:#?(\w+):\s*)?"(.+)"\s+by\s+(.+?)(?:\s+\((eps?\b[^)]*)\))?$',
  );

  // a trailing "(勇者)" in letters outside the Latin ones is the native name
  static final _native = RegExp(r'^(.*\S)\s*\(([^()]*)\)$');
  static final _latin = RegExp(r'^[\x00-\x7FÀ-ɏ]*$');

  static (String, String?) _splitNative(String text) {
    final match = _native.firstMatch(text);
    if (match == null) return (text, null);
    final inner = match.group(2)!;
    if (_latin.hasMatch(inner)) return (text, null);
    return (match.group(1)!, inner);
  }

  static String _trimZeros(String number) {
    final trimmed = number.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return trimmed.isEmpty ? number : trimmed;
  }
}
