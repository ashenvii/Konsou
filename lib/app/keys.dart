/// The client IDs, baked in at build time with `--dart-define-from-file=.env`.
/// A missing one is empty and the work that needs it stays off.
class Keys {
  const Keys({
    required this.malClientId,
    required this.googleClientId,
    required this.googleClientSecret,
  });

  const Keys.fromBuild()
    : malClientId = const String.fromEnvironment('MAL_CLIENT_ID'),
      googleClientId = const String.fromEnvironment('GOOGLE_CLIENT_ID'),
      googleClientSecret = const String.fromEnvironment('GOOGLE_CLIENT_SECRET');

  final String malClientId;
  final String googleClientId;
  final String googleClientSecret;

  bool get hasMal => malClientId.isNotEmpty;
  bool get hasGoogle => googleClientId.isNotEmpty;
}
