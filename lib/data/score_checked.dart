/// True for a saved detail row that has been asked for MAL's score. MAL leaves
/// mean out for an unscored title but always sends the scorer count, so a row
/// with no scorer count was saved before the score was asked for.
const scoreCheckedSql = "json_type(json, '\$.num_scoring_users') IS NOT NULL";
