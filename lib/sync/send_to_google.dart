import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../net/log.dart';
import '../net/request_timeout.dart';
import 'sync_errors.dart';

/// Sends one request to Google and returns the answer's text. A status in
/// [signInStatuses] means the sign-in is gone; any other error status, a
/// dropped connection or a failed TLS handshake is [DriveUnavailable].
Future<String> sendToGoogle(
  Future<http.Response> Function() request, {
  Set<int> signInStatuses = const {},
}) async {
  final http.Response response;
  try {
    response = await request().timeout(requestTimeout);
  } on Exception catch (error) {
    if (error is! TimeoutException &&
        error is! IOException &&
        error is! http.ClientException) {
      rethrow;
    }
    log('sync', 'google not reached: ${error.runtimeType}');
    throw DriveUnavailable();
  }
  if (signInStatuses.contains(response.statusCode)) throw SignInNeeded();
  if (response.statusCode >= 300) {
    log('sync', 'google status ${response.statusCode}');
    throw DriveUnavailable(response.statusCode);
  }
  // drive sends no charset on file content, and http would fall back to latin-1
  return utf8.decode(response.bodyBytes);
}

/// [sendToGoogle] for an answer that must be a JSON object. Anything else,
/// such as an html page sent with 200, is [DriveUnavailable].
Future<Map<String, dynamic>> sendForMap(
  Future<http.Response> Function() request, {
  Set<int> signInStatuses = const {},
}) async {
  final text = await sendToGoogle(request, signInStatuses: signInStatuses);
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    decoded = null;
  }
  if (decoded is Map<String, dynamic>) return decoded;
  log('sync', 'google answer was not json');
  throw DriveUnavailable();
}
