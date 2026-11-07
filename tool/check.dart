// The one command that runs every gate. Run it from the repo root:
//   check            (Windows, uses check.cmd)
//   dart run tool/check.dart
// It runs all gates even when one fails, prints a summary, and exits with 1 if
// any gate failed. `--fast` skips the analyzer and tests, for working on the
// gates themselves.
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
    results.add(('analyzer', await _flutter(['analyze'])));
    results.add(('tests', await _flutter(['test'])));
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

Future<bool> _flutter(List<String> args) async {
  stdout.writeln('\n> flutter ${args.join(' ')}');
  final process = await Process.start(
    'flutter',
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
  final sources = {
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart'))
        f.path.replaceAll('\\', '/'): f.readAsStringSync(),
  };
  final found = findDuplicates(sources);
  for (final d in found) {
    stdout.writeln('  $d');
  }
  return found.isEmpty;
}
