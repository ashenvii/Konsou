import 'package:konsou/sync/sync_record.dart';

Row buildEntry(
  String id, {
  String status = 'watching',
  int episodes = 0,
  int? score,
  String? notes,
  int addedAt = 1,
  int progressAt = 1,
  int scoreAt = 0,
  int notesAt = 0,
  int linkAt = 1,
  int? malId,
  String? name,
}) => orderColumns({
  'entry_id': id,
  'name': name,
  'status': status,
  'episodes_watched': episodes,
  'score': score,
  'notes': notes,
  'added_at': addedAt,
  'progress_changed_at': progressAt,
  'score_changed_at': scoreAt,
  'notes_changed_at': notesAt,
  'link_changed_at': linkAt,
  'references': [
    if (malId != null) {'provider': 'mal', 'provider_id': malId},
  ],
}, entryColumns);

Row buildCompletion(String id, int watch, int at, {bool estimated = false}) =>
    orderColumns({
      'entry_id': id,
      'watch_number': watch,
      'completed_at': at,
      'episodes_watched': 12,
      'is_estimated': estimated ? 1 : 0,
    }, completionColumns);

Row buildAlert(String id, int relatedId, {int seen = 0, int dismissed = 0}) =>
    orderColumns({
      'entry_id': id,
      'related_provider': 'mal',
      'related_provider_id': relatedId,
      'type': 'sequel',
      'seen': seen,
      'dismissed': dismissed,
      'created_at': 5,
    }, alertColumns);
