import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../sync/google_sign_in.dart';

/// The Google tokens in the system key store.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'google.tokens';

  final FlutterSecureStorage _storage;

  @override
  Future<GoogleTokens?> read() async {
    final text = await _storage.read(key: _key);
    if (text == null) return null;
    return GoogleTokens.fromJson(text);
  }

  @override
  Future<void> write(GoogleTokens tokens) =>
      _storage.write(key: _key, value: tokens.toJson());

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
