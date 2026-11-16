/// The picture for a title's hero band: one of MAL's extra pictures, so the
/// band does not repeat the cover standing on it. The choice is by the title's
/// id, so a title keeps its picture and different titles get different ones.
/// Null when MAL has no picture other than the main one.
String? pickHeroUrl({
  required int malId,
  required Object? pictures,
  String? mainLarge,
}) {
  if (pictures is! List) return null;
  final urls = <String>[];
  for (final picture in pictures) {
    if (picture is! Map) continue;
    final url = _large(picture);
    if (url != null && url != mainLarge) urls.add(url);
  }
  if (urls.isEmpty) return null;
  return urls[malId % urls.length];
}

String? _large(Map<Object?, Object?> picture) {
  final url = picture['large'] ?? picture['medium'];
  return url is String && url.isNotEmpty ? url : null;
}
