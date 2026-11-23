import 'dart:io';

IOSink? _sink;

/// Starts `logs/latest.log` in [folder]. The last run's file is kept as
/// `previous.log`. Until this runs, [log] does nothing.
Future<void> openLog(Directory folder) async {
  final separator = Platform.pathSeparator;
  try {
    final logs = Directory('${folder.path}${separator}logs');
    await logs.create(recursive: true);
    final latest = File('${logs.path}${separator}latest.log');
    if (await latest.exists()) {
      await latest.rename('${logs.path}${separator}previous.log');
    }
    final sink = latest.openWrite();
    // a full disk must never take the app down with it
    sink.done.catchError((Object _) {
      _sink = null;
    });
    _sink = sink;
  } on FileSystemException {
    // a second window holding the file, or a read-only folder: run without
    _sink = null;
  }
}

/// One line: time, [tag] (the area), [message]. Never put a title, a token or
/// anything from the user's Drive in a message.
void log(String tag, String message) {
  final sink = _sink;
  if (sink == null) return;
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final time =
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.'
      '${now.millisecond.toString().padLeft(3, '0')}';
  sink.writeln('$time $tag $message');
}

Future<void> closeLog() async {
  final sink = _sink;
  _sink = null;
  await sink?.close();
}
