// The one command that runs every gate. Run it from the repo root:
//   check            (Windows, uses check.cmd)
//   dart run tool/check.dart
// It runs all gates even when one fails, prints a summary, and exits with 1 if
// any gate failed. `--fast` skips code generation, the analyzer and tests, for
// working on the gates themselves.
import 'dart:io';

import 'duplicates.dart';
import 'tokens_check.dart';

const _tokensDart = 'lib/design/tokens.dart';
const _tokensMd = 'notes/design/tokens.md';

Future<void> main(List<String> args) async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run check from the repo root, where pubspec.yaml is.');
    exit(2);
  }
  final fast = args.contains('--fast');
  final results = <(String, bool)>[];

  if (!fast) {
    results.add(('generated code is current', await _generated()));
    results.add(('analyzer', await _run('flutter', ['analyze'])));
    results.add(('tests', await _run('flutter', ['test'])));
  }
  results.add(('tokens match tokens.md', _tokens()));
  results.add(('no duplicated code', _duplicates()));

  stdout.writeln('\n--- check ---');
  for (final (name, ok) in results) {
    stdout.writeln('${ok ? 'pass' : 'FAIL'}  $name');
  }
  final failed = results.where((r) => !r.$2).length;
  stdout.writeln(failed == 0 ? 'All gates pass.' : '$failed gate(s) failed.');
  exit(failed == 0 ? 0 : 1);
}

Future<bool> _run(String executable, List<String> args) async {
  stdout.writeln('\n> $executable ${args.join(' ')}');
  final process = await Process.start(
    executable,
    args,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  return await process.exitCode == 0;
}

bool _tokens() {
  stdout.writeln('\n> tokens against tokens.md');
  final md = File(_tokensMd);
  if (!md.existsSync()) {
    stdout.writeln('  $_tokensMd not found');
    return false;
  }
  final problems = tokenProblems(
    File(_tokensDart).readAsStringSync(),
    md.readAsStringSync(),
  );
  for (final p in problems) {
    stdout.writeln('  $p');
  }
  return problems.isEmpty;
}

bool _duplicates() {
  stdout.writeln('\n> duplicated code in lib/');
  final found = findDuplicates(
    _libFiles((path) => path.endsWith('.dart') && !path.endsWith('.g.dart')),
  );
  for (final d in found) {
    stdout.writeln('  $d');
  }
  return found.isEmpty;
}

/// Rebuilds drift's generated files and fails if that changed any of them, so
/// a stale `.g.dart` cannot be committed. The rebuilt files are left in place.
Future<bool> _generated() async {
  bool isGenerated(String path) => path.endsWith('.g.dart');
  final before = _libFiles(isGenerated);
  if (!await _run('dart', ['run', 'build_runner', 'build'])) return false;
  final after = _libFiles(isGenerated);
  final changed = {
    ...before.keys,
    ...after.keys,
  }.where((path) => before[path] != after[path]).toList();
  for (final path in changed) {
    stdout.writeln('  $path was out of date and is now rebuilt; commit it');
  }
  return changed.isEmpty;
}

Map<String, String> _libFiles(bool Function(String path) keep) => {
  for (final f in Directory('lib').listSync(recursive: true))
    if (f is File && keep(f.path))
      f.path.replaceAll('\\', '/'): f.readAsStringSync(),
};
