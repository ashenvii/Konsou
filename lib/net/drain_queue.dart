import 'log.dart';

/// Works through a queue of unfinished items one at a time, asking [next] for
/// the first one not in the skip set. [work] returns true when the item failed,
/// so it is left alone for the rest of the run and cannot hold the others up;
/// an item that throws counts as failed and is logged under [tag].
/// [onItem] runs after each one, so a screen can show what just arrived.
/// `finished` is true when nothing is left, false when [isStopped] ended it
/// early; `leftBehind` is true when a failed item was skipped, so a later run
/// may still get it.
Future<({bool finished, bool leftBehind})> drainQueue<T>({
  required String tag,
  required bool Function() isStopped,
  required Future<T?> Function(Set<T> skip) next,
  required Future<bool> Function(T item) work,
  void Function()? onItem,
}) async {
  final skip = <T>{};
  while (!isStopped()) {
    final item = await next(skip);
    if (item == null) return (finished: true, leftBehind: skip.isNotEmpty);
    bool failed;
    try {
      failed = await work(item);
    } catch (error) {
      log(tag, 'item failed: ${error.runtimeType}');
      failed = true;
    }
    if (failed) skip.add(item);
    onItem?.call();
  }
  return (finished: false, leftBehind: skip.isNotEmpty);
}
