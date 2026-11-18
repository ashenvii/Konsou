import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../data/databases.dart';
import '../data/details_database.dart';
import '../mal/request_gate.dart';
import 'cover_size.dart';

const defaultPoolLimit = 150 * 1024 * 1024;

const coverRequestGap = Duration(milliseconds: 100);

enum CoverOutcome { fetched, current, none, failed }

class CoverStore {
  CoverStore({
    required this.databases,
    required this.folder,
    required this.client,
    required this.gate,
    this.poolLimit = defaultPoolLimit,
    this.onSaved,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Databases databases;
  final Directory folder;
  final http.Client client;

  final RequestGate gate;
  final int poolLimit;

  final void Function(int malId)? onSaved;
  final DateTime Function() _now;

  DetailsDatabase get _details => databases.details;

  Future<File?> readCover(int malId, CoverSize size) async {
    final row = await _readRow(malId, size);
    if (row == null) return null;
    final file = _fileOf(row.fileName);
    if (!file.existsSync()) {
      await _deleteRow(malId, size);
      return null;
    }
    await (_details.update(_details.cover)..where(_coverFilter(malId, size)))
        .write(CoverCompanion(shownAt: Value(_now().millisecondsSinceEpoch)));
    return file;
  }

  /// Fetches the cover of [malId]. A title with no details saved, such as a
  /// recommendation, can name its picture in [pictureUrl].
  Future<CoverOutcome> fetchCover(
    int malId,
    CoverSize size, {
    required Lane lane,
    bool Function()? wanted,
    String? pictureUrl,
  }) async {
    final url = await _readUrl(malId, size) ?? pictureUrl;
    if (url == null) return CoverOutcome.none;
    final old = await _readRow(malId, size);
    if (old != null && old.url == url && _fileOf(old.fileName).existsSync()) {
      return CoverOutcome.current;
    }

    final http.Response response;
    try {
      response = await gate.send(
        lane,
        () => client.get(Uri.parse(url)),
        wanted: wanted,
      );
    } on Exception {
      return CoverOutcome.failed;
    }
    final isImage = (response.headers['content-type'] ?? '').startsWith(
      'image/',
    );
    if (response.statusCode != 200 || !isImage || response.bodyBytes.isEmpty) {
      return CoverOutcome.failed;
    }

    final fileName = '$malId-${size.name}${_extension(url)}';
    folder.createSync(recursive: true);
    _fileOf(fileName).writeAsBytesSync(response.bodyBytes);
    if (old != null && old.fileName != fileName) {
      _deleteFile(old.fileName);
    }
    final at = _now().millisecondsSinceEpoch;
    await _details
        .into(_details.cover)
        .insertOnConflictUpdate(
          CoverCompanion.insert(
            provider: 'mal',
            providerId: malId,
            size: size.name,
            url: url,
            fileName: fileName,
            bytes: response.bodyBytes.length,
            fetchedAt: at,
            shownAt: at,
          ),
        );
    onSaved?.call(malId);
    return CoverOutcome.fetched;
  }

  /// One of MAL's extra pictures of [malId], fetched once and kept beside the
  /// covers. Only the pictures of the last [keptPictureTitles] titles are
  /// kept, so they never pile up. Null when it cannot be fetched.
  Future<File?> pictureFile(
    int malId,
    String url, {
    bool Function()? wanted,
  }) async {
    final titleFolder = Directory(
      '${_pictures.path}${Platform.pathSeparator}$malId',
    );
    final file = File(
      '${titleFolder.path}${Platform.pathSeparator}'
      '${url.hashCode.toRadixString(36)}${_extension(url)}',
    );
    if (file.existsSync()) return file;
    final http.Response response;
    try {
      response = await gate.send(
        Lane.screen,
        () => client.get(Uri.parse(url)),
        wanted: wanted,
      );
    } on Exception {
      return null;
    }
    final isImage = (response.headers['content-type'] ?? '').startsWith(
      'image/',
    );
    if (response.statusCode != 200 || !isImage || response.bodyBytes.isEmpty) {
      return null;
    }
    titleFolder.createSync(recursive: true);
    file.writeAsBytesSync(response.bodyBytes);
    _keepRecentPictures();
    return file;
  }

  static const keptPictureTitles = 6;

  Directory get _pictures =>
      Directory('${folder.path}${Platform.pathSeparator}pictures');

  // the folders of titles seen longest ago go first
  void _keepRecentPictures() {
    final titles = _pictures.listSync().whereType<Directory>().toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    for (final old in titles.skip(keptPictureTitles)) {
      old.deleteSync(recursive: true);
    }
  }

  Future<Map<(int, CoverSize), File>> readKept() async {
    final rows = await (_details.select(
      _details.cover,
    )..where((row) => row.provider.equals('mal'))).get();
    return {
      for (final row in rows)
        (row.providerId, CoverSize.values.byName(row.size)): _fileOf(
          row.fileName,
        ),
    };
  }

  Future<File?> keptFile(int malId, CoverSize size) async {
    final row = await _readRow(malId, size);
    return row == null ? null : _fileOf(row.fileName);
  }

  Future<void> forgetMissingFiles() async {
    final rows = await _details.select(_details.cover).get();
    for (final row in rows) {
      if (!_fileOf(row.fileName).existsSync()) {
        await _deleteRow(row.providerId, CoverSize.values.byName(row.size));
      }
    }
  }

  Future<void> trimPool() async {
    final rows = await databases.record.customSelect('''
      SELECT cover.provider_id, cover.size, cover.file_name, cover.bytes
      FROM details.cover cover
      WHERE cover.provider = 'mal' AND (cover.size = 'large' OR NOT EXISTS (
        SELECT 1 FROM entry_reference reference
        WHERE reference.provider = 'mal'
          AND reference.provider_id = cover.provider_id))
      ORDER BY cover.shown_at, cover.provider_id
      ''').get();
    var total = rows.fold<int>(0, (sum, row) => sum + row.read<int>('bytes'));
    for (final row in rows) {
      if (total <= poolLimit) return;
      final size = CoverSize.values.byName(row.read<String>('size'));
      final malId = row.read<int>('provider_id');
      _deleteFile(row.read<String>('file_name'));
      await _deleteRow(malId, size);
      total -= row.read<int>('bytes');
    }
  }

  Expression<bool> Function(CoverTable) _coverFilter(
    int malId,
    CoverSize size,
  ) =>
      (row) =>
          row.provider.equals('mal') &
          row.providerId.equals(malId) &
          row.size.equals(size.name);

  Future<Cover?> _readRow(int malId, CoverSize size) => (_details.select(
    _details.cover,
  )..where(_coverFilter(malId, size))).getSingleOrNull();

  Future<void> _deleteRow(int malId, CoverSize size) =>
      (_details.delete(_details.cover)..where(_coverFilter(malId, size))).go();

  Future<Detail?> _readDetail(int malId) =>
      (_details.select(_details.detail)..where(
            (detail) =>
                detail.provider.equals('mal') & detail.providerId.equals(malId),
          ))
          .getSingleOrNull();

  Future<String?> _readUrl(int malId, CoverSize size) async {
    final row = await _readDetail(malId);
    if (row == null) return null;
    final url = size == CoverSize.medium
        ? row.coverMediumUrl
        : row.coverLargeUrl;
    return url == null || url.isEmpty ? null : url;
  }

  File _fileOf(String fileName) =>
      File('${folder.path}${Platform.pathSeparator}$fileName');

  void _deleteFile(String fileName) {
    final file = _fileOf(fileName);
    if (file.existsSync()) file.deleteSync();
  }

  String _extension(String url) {
    final name = Uri.parse(url).pathSegments.last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot);
  }
}
