/// Earlier start first, undated last; 0 when both are the same.
int compareStartDates(String? first, String? second) {
  if (first == second) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return first.compareTo(second);
}
