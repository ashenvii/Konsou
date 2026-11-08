import 'dart:convert';
import 'dart:io';

/// The titles of one saved MAL graph in test/mal/franchises/, as written by
/// tool/fetch_franchise_graphs.dart.
List<Map<String, dynamic>> readGraphTitles(String name) {
  final graph = jsonDecode(
    File('test/mal/franchises/$name.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (graph['titles'] as List).cast<Map<String, dynamic>>();
}

/// The relations of one saved title, as (id, title, relation type) maps.
List<Map<String, dynamic>> readRelations(Map<String, dynamic> title) =>
    (title['related'] as List).cast<Map<String, dynamic>>();
