import 'title_words.dart';

class TitleHit<K> {
  TitleHit(this.key, {required this.typos, required this.matchedWords});

  final K key;
  final int typos;
  final int matchedWords;
}

class _Title<K> {
  _Title(this.key, {required this.own, required this.length});

  final K key;
  final bool own;
  final int length;
}

class _Node {
  final children = <int, _Node>{};
  String? word;
  final titles = <int>[];
}

/// Every title word Konsou has seen, letter by letter, so one walk finds a
/// half typed word and a misspelled one together.
class TitleTree<K> {
  final _root = _Node();
  final _titles = <_Title<K>>[];

  /// Adds the titles one thing is known by. [own] marks the user's entries,
  /// which come before other titles in results.
  void add(K key, Iterable<String> titles, {bool own = false}) {
    for (final title in titles) {
      final words = foldWords(title);
      if (words.isEmpty) continue;
      final index = _titles.length;
      _titles.add(_Title(key, own: own, length: words.join(' ').length));
      for (final word in words) {
        var node = _root;
        for (final letter in word.runes) {
          node = node.children.putIfAbsent(letter, _Node.new);
        }
        node
          ..word = word
          ..titles.add(index);
      }
    }
  }

  /// Titles where at least half of the typed words start a word, within each
  /// word's typo allowance. One hit per key, best first.
  List<TitleHit<K>> find(String query) {
    final typedWords = foldWords(query);
    if (typedWords.isEmpty) return [];
    final typosByTitle = <int, List<int>>{};
    for (final typed in typedWords) {
      final best = <int, int>{};
      _walk(typed, (node, typos) {
        for (final title in node.titles) {
          if (typos < (best[title] ?? typos + 1)) best[title] = typos;
        }
      });
      best.forEach(
        (title, typos) => typosByTitle.putIfAbsent(title, () => []).add(typos),
      );
    }

    final bestByKey = <K, (_Title<K>, TitleHit<K>)>{};
    typosByTitle.forEach((index, typos) {
      if (typos.length * 2 < typedWords.length) return;
      final title = _titles[index];
      final hit = TitleHit(
        title.key,
        typos: typos.reduce((a, b) => a + b),
        matchedWords: typos.length,
      );
      final current = bestByKey[title.key];
      if (current == null || _compare(title, hit, current.$1, current.$2) < 0) {
        bestByKey[title.key] = (title, hit);
      }
    });
    final ranked = bestByKey.values.toList()
      ..sort((a, b) => _compare(a.$1, a.$2, b.$1, b.$2));
    return [for (final (_, hit) in ranked) hit];
  }

  /// The query with each word the tree does not know swapped for the closest
  /// word it does, for searching again when the provider finds nothing.
  String correctQuery(String query) =>
      [for (final typed in foldWords(query)) _correctWord(typed)].join(' ');

  String _correctWord(String typed) {
    _Node? closest;
    int? closestTypos;
    _walk(typed, (node, typos) {
      final better =
          closestTypos == null ||
          typos < closestTypos! ||
          (typos == closestTypos! &&
              node.titles.length > closest!.titles.length);
      if (better) {
        closest = node;
        closestTypos = typos;
      }
    });
    if (closest == null || closestTypos == 0) return typed;
    return closest!.word!;
  }

  /// Calls [visit] for every word that starts within [typed]'s allowance,
  /// with the fewest typos any of its beginnings needs.
  void _walk(String typed, void Function(_Node node, int typos) visit) {
    final letters = typed.runes.toList();
    final allowance = getTypoAllowance(typed);
    void descend(_Node node, List<int> row, int? matched) {
      for (final MapEntry(key: letter, value: child) in node.children.entries) {
        final next = stepTypoRow(row, letters, letter);
        var typos = matched;
        if (next.last <= allowance && (typos == null || next.last < typos)) {
          typos = next.last;
        }
        if (typos != null && child.word != null) visit(child, typos);
        final canStillMatch = next.reduce((a, b) => a < b ? a : b) <= allowance;
        if (typos != null || canStillMatch) descend(child, next, typos);
      }
    }

    descend(_root, startTypoRow(letters), null);
  }

  int _compare(_Title<K> a, TitleHit<K> aHit, _Title<K> b, TitleHit<K> bHit) {
    if (a.own != b.own) return a.own ? -1 : 1;
    if (aHit.typos != bHit.typos) return aHit.typos - bHit.typos;
    if (aHit.matchedWords != bHit.matchedWords) {
      return bHit.matchedWords - aHit.matchedWords;
    }
    return a.length - b.length;
  }
}
