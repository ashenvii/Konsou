import 'dart:convert';

import 'package:http/http.dart' as http;

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
    final body = await _send(() async => http.Request('GET', url));
    final files = (jsonDecode(body) as Map<String, dynamic>)['files'] as List;
    if (files.isEmpty) return null;
    return _parseFile(files.first as Map<String, dynamic>);
  }

  Future<String> downloadFile(String id) => _send(
    () async => http.Request('GET', Uri.parse('$_files/$id?alt=media')),
  );

  Future<DriveFile> createFile(String name, String content) async {
    const boundary = 'konsou-record';
    final metadata = jsonEncode({
      'name': name,
      'parents': ['appDataFolder'],
    });
    final body = await _send(() async {
      final request = http.Request(
        'POST',
        Uri.parse('$_uploads?uploadType=multipart&fields=id,version'),
      );
      request.headers['Content-Type'] = 'multipart/related; boundary=$boundary';
      request.body =
          '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
          '$metadata\r\n--$boundary\r\nContent-Type: application/json\r\n\r\n'
          '$content\r\n--$boundary--';
      return request;
    });
    return _parseFile(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<DriveFile> updateFile(String id, String content) async {
    final body = await _send(() async {
      final request = http.Request(
        'PATCH',
        Uri.parse('$_uploads/$id?uploadType=media&fields=id,version'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = content;
      return request;
    });
    return _parseFile(jsonDecode(body) as Map<String, dynamic>);
  }

  DriveFile _parseFile(Map<String, dynamic> file) =>
      DriveFile(file['id'] as String, '${file['version']}');

  Future<String> _send(Future<http.Request> Function() build) async {
    final request = await build();
    request.headers['Authorization'] = 'Bearer ${await _accessToken()}';
    final response = await sendToGoogle(
      () async => http.Response.fromStream(await _client.send(request)),
    );
    if (response.statusCode == 401) throw SignInNeeded();
    if (response.statusCode >= 300) throw DriveUnavailable(response.statusCode);
    // drive sends no charset on file content, and http would fall back to latin-1
    return utf8.decode(response.bodyBytes);
  }
}
