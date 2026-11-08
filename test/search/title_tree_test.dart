import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/search/title_tree.dart';

void main() {
  TitleTree<String> buildTree() => TitleTree<String>()
    ..add('frieren', ['Sousou no Frieren', 'Frieren: Beyond Journey\'s End'])
    ..add('frieren special', ['Sousou no Frieren: ●● no Mahou Part 2'])
    ..add('one piece', ['One Piece'], own: true)
    ..add('one punch', ['One Punch Man'])
    ..add('kanketsu', ['Shingeki no Kyojin: The Final Season - Kanketsu-hen'])
    ..add('japanese', ['葬送のフリーレン']);

  List<String> find(TitleTree<String> tree, String query) => [
    for (final hit in tree.find(query)) hit.key,
  ];

  test('a half typed word finds titles as you type', () {
    final tree = buildTree();
    expect(find(tree, 'frier'), ['frieren', 'frieren special']);
    expect(find(tree, 'fr'), ['frieren', 'frieren special']);
  });

  test('typos are forgiven by word length', () {
    final tree = buildTree();
    expect(find(tree, 'frieran').first, 'frieren');
    // a swap is two changed letters
    expect(find(tree, 'freiren'), isEmpty);
    expect(find(tree, 'kanektsu'), ['kanketsu']);
    // three letters allow no typo
    expect(find(tree, 'onr'), isEmpty);
  });

  test('own entries come first, then fewest typos, then shortest title', () {
    final tree = buildTree();
    expect(find(tree, 'one'), ['one piece', 'one punch']);
    final hits = tree.find('frieren');
    expect(hits.first.key, 'frieren');
    expect(hits.first.typos, 0);
  });

  test('half of the typed words must match', () {
    final tree = buildTree();
    expect(find(tree, 'frieren mahou'), ['frieren special', 'frieren']);
    expect(find(tree, 'frieren mahou part zzzz'), ['frieren special']);
    expect(find(tree, 'one zzzz yyyy'), isEmpty);
  });

  test('japanese matches by prefix with no typo', () {
    final tree = buildTree();
    expect(find(tree, '葬送の'), ['japanese']);
    expect(find(tree, '葬迭の'), isEmpty);
  });

  test('a query is corrected to words the tree knows', () {
    final tree = buildTree();
    expect(tree.correctQuery('sousou no frieran'), 'sousou no frieren');
    expect(tree.correctQuery('frier'), 'frier');
    expect(tree.correctQuery('zzzz piece'), 'zzzz piece');
  });
}
