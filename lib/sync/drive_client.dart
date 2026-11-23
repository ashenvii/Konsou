import 'dart:convert';

import 'package:http/http.dart' as http;

import 'send_to_google.dart';
import 'sync_errors.dart';

const _files = 'https://www.googleapis.com/drive/v3/files';
const _uploads = 'https://www.googleapis.com/upload/drive/v3/files';

/// A file in the hidden app folder. [version] goes up with every change on
/// Drive's side, so an unchanged version means nothing new to download.
class DriveFile {
  DriveFile(this.id, this.version);

  final String id;
  final String version;
}

/// Reads and writes files in the user's hidden Drive app folder, the same
/// folder the old app used.
class DriveClient {
  DriveClient({required this._client, required this._accessToken});

  final http.Client _client;
  final Future<String> Function() _accessToken;

  Future<DriveFile?> findFile(String name) async {
    final url = Uri.parse(_files).replace(
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$name' and trashed = false",
        'fields': 'files(id,version)',
        // two devices syncing for the first time can each create the file;
        // all of them settle on the oldest
        'orderBy': 'createdTime',
      },
    );
    final reply = await sendForMap(
      await _authorize(http.Request('GET', url)),
      signInStatuses: const {401},
    );
    if (reply['files'] case final List files) {
      return files.isEmpty ? null : _parseFile(files.first);
    }
    throw DriveUnavailable();
  }

  Future<String> downloadFile(String id) async => sendToGoogle(
    await _authorize(http.Request('GET', Uri.parse('$_files/$id?alt=media'))),
    signInStatuses: const {401},
  );

  Future<DriveFile> createFile(String name, String content) async {
    const boundary = 'konsou-record';
    final metadata = jsonEncode({
      'name': name,
      'parents': ['appDataFolder'],
    });
    final request = http.Request(
      'POST',
      Uri.parse('$_uploads?uploadType=multipart&fields=id,version'),
    );
    request.headers['Content-Type'] = 'multipart/related; boundary=$boundary';
    request.body =
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n--$boundary\r\nContent-Type: application/json\r\n\r\n'
        '$content\r\n--$boundary--';
    final reply = await sendForMap(
      await _authorize(request),
      signInStatuses: const {401},
    );
    return _parseFile(reply);
  }

  Future<DriveFile> updateFile(String id, String content) async {
    final request = http.Request(
      'PATCH',
      Uri.parse('$_uploads/$id?uploadType=media&fields=id,version'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = content;
    final reply = await sendForMap(
      await _authorize(request),
      signInStatuses: const {401},
    );
    return _parseFile(reply);
  }

  DriveFile _parseFile(Object? file) => switch (file) {
    {'id': final String id, 'version': final Object version} => DriveFile(
      id,
      '$version',
    ),
    _ => throw DriveUnavailable(),
  };

  // the token is read before sending, so a refresh never eats the timeout
  Future<Future<http.Response> Function()> _authorize(
    http.Request request,
  ) async {
    request.headers['Authorization'] = 'Bearer ${await _accessToken()}';
    return () async => http.Response.fromStream(await _client.send(request));
  }
}
