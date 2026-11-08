import 'dart:io';

/// The MAL client ID from `.env`, for the scripts in tool/. Never committed.
String readMalClientId() {
  for (final line in File('.env').readAsLinesSync()) {
    if (line.startsWith('MAL_CLIENT_ID=')) {
      final id = line.substring('MAL_CLIENT_ID='.length).trim();
      if (id.isNotEmpty) return id;
    }
  }
  stderr.writeln('MAL_CLIENT_ID is missing from .env');
  exit(2);
}
