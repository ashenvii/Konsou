import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'sync_errors.dart';

const _authorizeUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
const _tokenUrl = 'https://oauth2.googleapis.com/token';
const _userInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';

/// The same scope the old app asked for, so its Drive backups stay readable.
const googleScope =
    'openid email profile https://www.googleapis.com/auth/drive.appdata';

class GoogleTokens {
  GoogleTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.email,
  });

  factory GoogleTokens.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return GoogleTokens(
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiresAt: map['expires_at'] as int,
      email: map['email'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final String email;

  String toJson() => jsonEncode({
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt,
    'email': email,
  });
}

/// Where the tokens are kept. The app fills it with the system key store.
abstract interface class TokenStore {
  Future<GoogleTokens?> read();
  Future<void> write(GoogleTokens tokens);
  Future<void> clear();
}

/// The user closed Google's page or said no.
class SignInCancelled implements Exception {
  @override
  String toString() => 'SignInCancelled';
}

/// Google sign-in for Drive. The browser opens Google's page and the answer
/// comes back to a port on 127.0.0.1, on Windows and Android alike.
class GoogleSignIn {
  GoogleSignIn({
    required this.clientId,
    required this.clientSecret,
    required this._client,
    required this._store,
    required this._openBrowser,
    DateTime Function()? now,
    this.timeout = const Duration(minutes: 2),
  }) : _now = now ?? DateTime.now;

  final String clientId;
  final String clientSecret;
  final Duration timeout;
  final http.Client _client;
  final TokenStore _store;
  final Future<void> Function(Uri url) _openBrowser;
  final DateTime Function() _now;

  Future<bool> isSignedIn() async => await _store.read() != null;

  /// Runs the browser sign-in and keeps the tokens. Returns the account email.
  Future<String> signIn() async {
    final verifier = _randomText(64);
    final state = _randomText(32);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}/callback';
    final answer = server
        .firstWhere((request) => request.uri.path == '/callback')
        .timeout(timeout);
    try {
      await _openBrowser(
        Uri.parse(_authorizeUrl).replace(
          queryParameters: {
            'client_id': clientId,
            'redirect_uri': redirectUri,
            'response_type': 'code',
            'scope': googleScope,
            'code_challenge': base64Url
                .encode(sha256.convert(ascii.encode(verifier)).bytes)
                .replaceAll('=', ''),
            'code_challenge_method': 'S256',
            'state': state,
            'access_type': 'offline',
            // without it google only sends a refresh token the first time
            'prompt': 'consent',
          },
        ),
      );
      final request = await answer;
      final query = request.uri.queryParameters;
      final code = query['code'];
      final accepted = code != null && query['state'] == state;
      request.response
        ..headers.contentType = ContentType.html
        ..write(
          accepted
              ? '<p>Done. You can close this tab and go back to Konsou.</p>'
              : '<p>Sign-in was cancelled. You can close this tab.</p>',
        );
      await request.response.close();
      if (!accepted) throw SignInCancelled();

      final tokens = await _postToken({
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      });
      final refreshToken = tokens['refresh_token'] as String?;
      if (refreshToken == null) throw SignInCancelled();
      final accessToken = tokens['access_token'] as String;
      final email = await _readEmail(accessToken);
      await _store.write(
        GoogleTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: _expiresAt(tokens),
          email: email,
        ),
      );
      return email;
    } on TimeoutException {
      throw SignInCancelled();
    } finally {
      // the browser may never answer; that wait must not fail on its own later
      answer.ignore();
      await server.close(force: true);
    }
  }

  /// A working access token, refreshed when it ends within a minute.
  Future<String> accessToken() async {
    final tokens = await _store.read();
    if (tokens == null) throw SignInNeeded();
    final soon = _now().add(const Duration(minutes: 1)).millisecondsSinceEpoch;
    if (tokens.expiresAt > soon) return tokens.accessToken;
    final refreshed = await _postToken({
      'refresh_token': tokens.refreshToken,
      'grant_type': 'refresh_token',
    });
    final accessToken = refreshed['access_token'] as String;
    await _store.write(
      GoogleTokens(
        accessToken: accessToken,
        refreshToken:
            refreshed['refresh_token'] as String? ?? tokens.refreshToken,
        expiresAt: _expiresAt(refreshed),
        email: tokens.email,
      ),
    );
    return accessToken;
  }

  /// Forgets the tokens. The list on this device and the Drive copy stay.
  Future<void> signOut() => _store.clear();

  Future<Map<String, dynamic>> _postToken(Map<String, String> fields) async {
    final response = await sendToGoogle(
      () => _client.post(
        Uri.parse(_tokenUrl),
        body: {'client_id': clientId, 'client_secret': clientSecret, ...fields},
      ),
    );
    // google answers 400 invalid_grant when a refresh token is revoked or expired
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw SignInNeeded();
    }
    if (response.statusCode >= 300) throw DriveUnavailable(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String> _readEmail(String accessToken) async {
    final response = await sendToGoogle(
      () => _client.get(
        Uri.parse(_userInfoUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode >= 300) throw DriveUnavailable(response.statusCode);
    return (jsonDecode(response.body) as Map<String, dynamic>)['email']
        as String;
  }

  int _expiresAt(Map<String, dynamic> tokens) => _now()
      .add(Duration(seconds: tokens['expires_in'] as int))
      .millisecondsSinceEpoch;
}

const _letters =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
final _random = Random.secure();

String _randomText(int length) => String.fromCharCodes([
  for (var i = 0; i < length; i++)
    _letters.codeUnitAt(_random.nextInt(_letters.length)),
]);
