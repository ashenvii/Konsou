import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../data/databases.dart';
import '../data/details_database.dart';
import '../mal/request_gate.dart';
import 'cover_size.dart';

/// The pool of large covers and covers of titles not on the list holds this
/// many bytes before the least recently shown go.
const defaultPoolLimit = 150 * 1024 * 1024;

/// Time between cover downloads. MAL asks for 0.5 seconds on its API; its
/// image server publishes no limit, so covers go five times faster.
const coverRequestGap = Duration(milliseconds: 100);

enum CoverOutcome { fetched, current, none, failed }

/// Cover files kept on the device, one folder, named by MAL id and size. The
/// medium cover of every entry on the list is always kept; the rest share a
/// capped pool.
class CoverStore {
  CoverStore({
    required this.databases,
    required this.folder,
    required this.client,
    required this.gate,
    this.poolLimit = defaultPoolLimit,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Databases databases;
  final Directory folder;
  final http.Client client;

  /// Covers come from MAL's image server, so they get a gate of their own and
  /// never hold up the API requests.
  final RequestGate gate;
  final int poolLimit;
  final DateTime Function() _now;

  DetailsDatabase get _details => databases.details;

  /// The kept file, or null. Showing it notes the time, for the pool.
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

  /// Keeps this cover from the picture link in the title's details, unless
  /// that exact link is already kept. A changed link replaces the old file.
  Future<CoverOutcome> fetchCover(
    int malId,
    CoverSize size, {
    required Lane lane,
  }) async {
    final url = await _readUrl(malId, size);
    if (url == null) return CoverOutcome.none;
    final old = await _readRow(malId, size);
    if (old != null && old.url == url && _fileOf(old.fileName).existsSync()) {
      return CoverOutcome.current;
    }

    final http.Response response;
    try {
      response = await gate.send(lane, () => client.get(Uri.parse(url)));
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
    return CoverOutcome.fetched;
  }

  /// Forgets covers whose file is gone, so the cover trickle fetches them
  /// again.
  Future<void> forgetMissingFiles() async {
    final rows = await _details.select(_details.cover).get();
    for (final row in rows) {
      if (!_fileOf(row.fileName).existsSync()) {
        await _deleteRow(row.providerId, CoverSize.values.byName(row.size));
      }
    }
  }

  /// Drops the least recently shown pool covers until the pool fits. The pool
  /// is every large cover and every cover of a title no entry points to.
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

  Future<String?> _readUrl(int malId, CoverSize size) async {
    final row =
        await (_details.select(_details.detail)..where(
              (detail) =>
                  detail.provider.equals('mal') &
                  detail.providerId.equals(malId),
            ))
            .getSingleOrNull();
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
