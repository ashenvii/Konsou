import '../data/record_database.dart';
import 'franchise_grouping.dart';
import 'saved_titles.dart';

class FranchiseMembers {
  const FranchiseMembers(this.saved, this.places, this.members);

  final Map<int, SavedTitle> saved;
  final Map<int, FranchisePlace> places;

  final List<FranchiseTitle> members;
}

Future<FranchiseMembers?> readFranchiseMembers(
  RecordDatabase record,
  int malId,
) async {
  final saved = await readSavedTitles(record);
  final places = groupFranchises(saved.values.map((title) => title.title));
  final franchise = places[malId]?.franchiseId;
  if (franchise == null) return null;
  return FranchiseMembers(
    saved,
    places,
    sortByStart([
      for (final title in saved.values)
        if (places[title.title.id]?.franchiseId == franchise) title.title,
    ]),
  );
}
