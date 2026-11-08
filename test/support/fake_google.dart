import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konsou/sync/google_sign_in.dart';

/// A file in the fake app folder.
class FakeDriveFile {
  FakeDriveFile(this.name, this.content);

  final String name;
  String content;
  int version = 1;
}

/// Google's token endpoint and Drive's app folder, answering in the shapes
/// the Drive v3 and OAuth documentation give. Nothing leaves the test.
class FakeGoogle {
  final files = <String, FakeDriveFile>{};
  final asked = <String>[];
  var validToken = 'token-1';
  var refreshAnswer = 200;
  int? driveFailure;
  int? uploadFailure;
  var uploads = 0;
  var _nextId = 1;

  /// Files are kept oldest first, the order `orderBy=createdTime` asks for.
  void addFile(String name, String content) =>
      files['id-${_nextId++}'] = FakeDriveFile(name, content);

  FakeDriveFile? file(String name) {
    for (final file in files.values) {
      if (file.name == name) return file;
    }
    return null;
  }

  late final http.Client client = MockClient(_answer);

  Future<http.Response> _answer(http.Request request) async {
    final url = request.url;
    asked.add('${request.method} ${url.host}${url.path}');
    if (url.host == 'oauth2.googleapis.com') return _token(request);
    if (url.path == '/oauth2/v2/userinfo') {
      return _json({'email': 'owner@example.com'});
    }
    if (request.headers['Authorization'] != 'Bearer $validToken') {
      return http.Response('', 401);
    }
    final failure = driveFailure;
    if (failure != null) return http.Response('', failure);

    final segments = url.pathSegments;
    if (request.method == 'GET' && segments.last == 'files') {
      final name = RegExp(r"name = '([^']+)'")
          .firstMatch(url.queryParameters['q']!)!;
      return _json({
        'files': [
          for (final MapEntry(:key, :value) in files.entries)
            if (value.name == name.group(1))
              {'id': key, 'version': '${value.version}'},
        ],
      });
    }
    if (request.method == 'GET') {
      return http.Response.bytes(
        utf8.encode(files[segments.last]!.content),
        200,
      );
    }
    final failedUpload = uploadFailure;
    if (failedUpload != null) return http.Response('', failedUpload);
    if (request.method == 'POST') {
      final parts = request.body.split('\r\n\r\n');
      final metadata = jsonDecode(parts[1].split('\r\n').first) as Map;
      final content = parts[2].split('\r\n--').first;
      addFile(metadata['name'] as String, content);
      uploads++;
      return _json({'id': files.keys.last, 'version': '1'});
    }
    final file = files[segments.last]!;
    file
      ..content = request.body
      ..version += 1;
    uploads++;
    return _json({'id': segments.last, 'version': '${file.version}'});
  }

  http.Response _token(http.Request request) {
    final fields = request.bodyFields;
    if (fields['grant_type'] == 'refresh_token') {
      if (refreshAnswer != 200) {
        return http.Response('{"error":"invalid_grant"}', refreshAnswer);
      }
      validToken = 'token-refreshed';
      return _json({'access_token': validToken, 'expires_in': 3600});
    }
    return _json({
      'access_token': validToken,
      'refresh_token': 'refresh-1',
      'expires_in': 3600,
    });
  }

  http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}

class MemoryTokenStore implements TokenStore {
  GoogleTokens? tokens;

  @override
  Future<GoogleTokens?> read() async => tokens;

  @override
  Future<void> write(GoogleTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}
