/// One MAL title as the grouping sees it: what it is and its relations.
class FranchiseTitle {
  const FranchiseTitle({
    required this.id,
    required this.mediaType,
    required this.startDate,
    required this.relations,
  });

  final int id;
  final String? mediaType;
  final String? startDate;
  final List<TitleRelation> relations;
}

/// One of MAL's related titles, with MAL's own word for the relation.
class TitleRelation {
  const TitleRelation(this.id, this.type);

  final int id;
  final String type;
}

/// Where a title landed: the franchise (named after one of its titles) and
/// whether it is an extra there rather than part of the story.
class FranchisePlace {
  const FranchisePlace({required this.franchiseId, required this.isExtra});

  final int franchiseId;
  final bool isExtra;
}

const storyRelations = {'sequel', 'prequel'};

/// Relations that name a parent, and whether the title holding the relation
/// is the extra: a parent lists its side stories and summaries, an extra
/// names its parent story or full story.
const parentRelations = {
  'side_story': false,
  'summary': false,
  'parent_story': true,
  'full_story': true,
};

/// Groups titles into franchises. Only a sequel or prequel both titles list
/// makes a story: MAL sometimes lists one from one side only, and counting
/// those would move a title between story and extra depending on what else
/// was fetched. Nothing depends on the order the titles come in.
Map<int, FranchisePlace> groupFranchises(Iterable<FranchiseTitle> titles) {
  final byId = {for (final title in titles) title.id: title};
  final stories = _UnionFind();
  final parents = <int, Set<int>>{};
  for (final title in byId.values) {
    stories.find(title.id);
    for (final relation in title.relations) {
      final other = byId[relation.id];
      if (storyRelations.contains(relation.type) &&
          other != null &&
          other.relations.any(
            (back) => back.id == title.id && storyRelations.contains(back.type),
          )) {
        stories.union(title.id, relation.id);
      }
      final holderIsExtra = parentRelations[relation.type];
      if (holderIsExtra == true) {
        parents.putIfAbsent(title.id, () => {}).add(relation.id);
      } else if (holderIsExtra == false) {
        parents.putIfAbsent(relation.id, () => {}).add(title.id);
      }
    }
  }

  final storySize = <int, int>{};
  for (final id in byId.keys) {
    final story = stories.find(id);
    storySize[story] = (storySize[story] ?? 0) + 1;
  }

  // a title with no story of its own joins its parents' franchise when they
  // all agree; a TV series never does
  int findFranchise(int id, Set<int> seen) {
    final title = byId[id];
    if (title == null ||
        title.mediaType == 'tv' ||
        storySize[stories.find(id)] != 1) {
      return stories.find(id);
    }
    final claims = {
      for (final parent in parents[id] ?? const <int>{})
        if (parent != id && !seen.contains(parent))
          findFranchise(parent, {...seen, id}),
    };
    return claims.length == 1 ? claims.single : stories.find(id);
  }

  final franchiseByTitle = {
    for (final id in byId.keys) id: findFranchise(id, const {}),
  };

  final storyTitles = <int, List<FranchiseTitle>>{};
  for (final MapEntry(key: id, value: franchise) in franchiseByTitle.entries) {
    if (franchise == stories.find(id)) {
      storyTitles.putIfAbsent(franchise, () => []).add(byId[id]!);
    }
  }
  final names = {
    for (final MapEntry(key: franchise, value: story) in storyTitles.entries)
      franchise:
          sortByStart(story.where((title) => title.mediaType == 'tv'))
              .firstOrNull ??
          sortByStart(story).first,
  };

  return {
    for (final MapEntry(key: id, value: franchise) in franchiseByTitle.entries)
      id: FranchisePlace(
        franchiseId: names[franchise]?.id ?? franchise,
        isExtra: franchise != stories.find(id),
      ),
  };
}

/// Titles from the earliest start to the latest. Undated (upcoming) titles
/// come last; the smaller id breaks ties.
List<FranchiseTitle> sortByStart(Iterable<FranchiseTitle> titles) =>
    titles.toList()..sort((a, b) {
      final dateA = a.startDate;
      final dateB = b.startDate;
      if (dateA == dateB) return a.id.compareTo(b.id);
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });

class _UnionFind {
  final _parent = <int, int>{};

  int find(int id) {
    var root = _parent.putIfAbsent(id, () => id);
    while (root != _parent[root]) {
      root = _parent[root]!;
    }
    _parent[id] = root;
    return root;
  }

  void union(int a, int b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA != rootB) _parent[rootA] = rootB;
  }
}
