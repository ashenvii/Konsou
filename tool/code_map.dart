/// Writes CODE_MAP.md: every public thing in lib/, what it does, what it
/// takes, where it is used and which tests cover it. `check` runs it on every
/// run and fails on the problems it finds, so the map cannot fall behind.
///   dart run tool/code_map.dart
library;

import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Where the map is written, at the repo root. Gitignored.
const codeMapPath = 'CODE_MAP.md';

/// What each folder in lib/ is for. check fails when a folder with Dart files
/// is missing here, or when one listed here is gone.
const folderPurposes = <String, String>{
  'lib': 'main.dart: opens the window, the databases and the services, then runs the app.',
  'lib/app': 'Wiring between data and screens: providers, routes, keyboard shortcuts, the quick search and toast layers.',
  'lib/components': 'Shared widgets every screen builds from. Reuse one before writing a new one.',
  'lib/covers': 'Cover images: picks the size, keeps them on disk and fetches missing ones in the background.',
  'lib/data': 'The two databases (record.db for your list, details.db for MAL facts) and small data helpers.',
  'lib/design': 'Tokens and text styles. Every color, size, space and duration comes from here.',
  'lib/detail': 'What a title page shows, worked out from the databases: facts, watch order, recommendations.',
  'lib/gallery': 'The component gallery, a dev screen that shows each component in its states.',
  'lib/icons': 'Icons drawn on a 16 grid, and the painter that draws them.',
  'lib/import': 'Reads the old app\'s list into record.db.',
  'lib/library': 'Library rows worked out from the databases: status, counts, franchise folding, sorting and finding.',
  'lib/mal': 'The MAL API: one request kind per file, the request gate, the trickle, franchise scan and matching.',
  'lib/net': 'Request plumbing shared by MAL, covers and sync: backoff, queues, timeouts and the log.',
  'lib/screens/detail': 'The title page, one widget per part.',
  'lib/screens/library':
      'The Library screen: grid, list, heading, quick panel and their parts.',
  'lib/search': 'The title index behind Quick search and Find.',
  'lib/shell': 'The window frame: title bar, rail, window buttons and remembered placement.',
  'lib/sync': 'Google sign in and Drive sync of record.db.',
};

/// Classes whose subclasses are widgets.
const _widgetBases = {
  'StatelessWidget',
  'StatefulWidget',
  'ConsumerWidget',
  'ConsumerStatefulWidget',
  'InheritedWidget',
  'InheritedNotifier',
  'InheritedModel',
};

/// One public top-level declaration in lib/.
class Thing {
  Thing({
    required this.name,
    required this.kind,
    required this.path,
    required this.line,
    required this.doc,
    this.superclass,
    this.isRiverpod = false,
    this.takes = const [],
    this.has = const [],
  });

  final String name;
  String kind;
  final String path;
  final int line;
  final String? doc;
  final String? superclass;
  final bool isRiverpod;
  final List<String> takes;
  List<String> has;

  /// The name other files write: riverpod's generated `fooProvider` for `foo`.
  String get usedAs => isRiverpod
      ? '${name[0].toLowerCase()}${name.substring(1)}Provider'
      : name;
}

/// The written map and what check should fail on.
class CodeMap {
  const CodeMap(this.markdown, this.problems);
  final String markdown;
  final List<String> problems;
}

/// Builds the map from [lib] and [tests], each a map of repo-relative path to
/// source, with [purposes] for the folders. Generated `.g.dart` files are
/// left out by the caller.
CodeMap buildCodeMap(
  Map<String, String> lib,
  Map<String, String> tests, {
  Map<String, String> purposes = folderPurposes,
}) {
  final problems = <String>[];
  final things = <Thing>[];
  final namesByFile = <String, LinkedHashSet<String>>{};
  final linksByFile = <String, _Links>{};

  for (final path in lib.keys.toList()..sort()) {
    final parsed = parseString(
      content: lib[path]!,
      path: path,
      throwIfDiagnostics: false,
    );
    things.addAll(_readThings(path, parsed.unit, parsed.lineInfo));
    namesByFile[path] = _namesIn(parsed.unit);
    linksByFile[path] = _linksOf(path, parsed.unit);
  }
  final testNames = <String, LinkedHashSet<String>>{};
  for (final path in tests.keys.toList()..sort()) {
    final unit = parseString(
      content: tests[path]!,
      path: path,
      throwIfDiagnostics: false,
    ).unit;
    testNames[path] = _namesIn(unit);
    linksByFile[path] = _linksOf(path, unit);
  }

  // a name counts as a use only where the file imports its definition,
  // directly or through a file that exports it, so flutter's Row is not ours
  final reachCache = <String, Set<String>>{};
  Set<String> reach(String path) => reachCache.putIfAbsent(path, () {
    final seen = <String>{path};
    final todo = [...?linksByFile[path]?.imports];
    while (todo.isNotEmpty) {
      final next = todo.removeLast();
      if (seen.add(next)) todo.addAll(linksByFile[next]?.exports ?? const {});
    }
    return seen;
  });

  _markWidgets(things);

  final byName = <String, List<Thing>>{};
  for (final t in things) {
    byName.putIfAbsent(t.usedAs, () => []).add(t);
    if (t.doc == null) {
      problems.add('${t.path}:${t.line} ${t.name} has no /// line');
    }
  }
  for (final MapEntry(key: name, value: same) in byName.entries) {
    if (same.length > 1) {
      problems.add(
        '$name is declared ${same.length} times: '
        '${same.map((t) => '${t.path}:${t.line}').join(', ')}',
      );
    }
  }

  final folders = {for (final path in lib.keys) _folderOf(path)};
  for (final f in folders.difference(purposes.keys.toSet())) {
    problems.add('$f has no line in folderPurposes in tool/code_map.dart');
  }
  for (final f in purposes.keys.toSet().difference(folders)) {
    problems.add('$f is in folderPurposes but has no Dart files');
  }

  Thing? find(String name, String inFile) {
    final found = byName[name];
    if (found == null || found.length != 1) return null;
    return reach(inFile).contains(found.single.path) ? found.single : null;
  }

  final usedIn = {for (final t in things) t: <String>{}};
  for (final MapEntry(key: path, value: names) in namesByFile.entries) {
    for (final name in names) {
      final t = find(name, path);
      if (t != null && t.path != path) usedIn[t]!.add(path);
    }
  }
  final testedIn = {for (final t in things) t: <String>{}};
  for (final MapEntry(key: path, value: names) in testNames.entries) {
    for (final name in names) {
      final t = find(name, path);
      if (t != null) testedIn[t]!.add(path);
    }
  }

  final widgetsUsedBy = <String, List<Thing>>{};
  for (final MapEntry(key: path, value: names) in namesByFile.entries) {
    widgetsUsedBy[path] = [
      for (final name in names)
        if (find(name, path) case final t?
            when t.kind == 'widget' && t.path != path)
          t,
    ];
  }
  final roots = [
    for (final name in namesByFile['lib/app/routes.dart'] ?? <String>{})
      if (find(name, 'lib/app/routes.dart') case final t?
          when t.kind == 'widget')
        t,
  ];

  final out = StringBuffer()
    ..writeln('# Code map')
    ..writeln()
    ..writeln(
      'Written by `tool/code_map.dart` on every `check`. Never edit it by '
      'hand: change the code or its `///` line and run check.',
    )
    ..writeln()
    ..writeln(
      'Search it for a name. Each thing shows its kind, its file and line, '
      'its `///` line, what it takes, where it is used and which tests '
      'cover it. Paths under "used in" are inside `lib/`; paths under '
      '"tests" are inside `test/` unless they start with `integration_test/`.',
    )
    ..writeln()
    ..writeln(
      '${lib.length} files, ${things.length} public things, '
      '${things.where((t) => t.kind == 'widget').length} of them widgets.',
    )
    ..writeln()
    ..writeln('## How it fits together')
    ..writeln()
    ..writeln(
      'Each folder, what it is for, which folders it imports and which '
      'import it.',
    )
    ..writeln();
  final importedBy = <String, Set<String>>{};
  final leansOn = <String, Set<String>>{};
  for (final path in lib.keys) {
    final from = _folderOf(path);
    for (final to in linksByFile[path]!.imports.map(_folderOf)) {
      if (to == from) continue;
      leansOn.putIfAbsent(from, () => {}).add(to);
      importedBy.putIfAbsent(to, () => {}).add(from);
    }
  }
  for (final f in folders.toList()..sort()) {
    out
      ..writeln('- **$f**: ${purposes[f] ?? '(no line yet)'}')
      ..writeln('  - imports: ${_list(leansOn[f], short: true)}')
      ..writeln('  - imported by: ${_list(importedBy[f], short: true)}');
  }

  out
    ..writeln()
    ..writeln('## Screens')
    ..writeln()
    ..writeln(
      'The widgets each route builds, from `lib/app/routes.dart` down. A '
      'widget is opened out the first time it appears; later it shows '
      '"(above)".',
    )
    ..writeln()
    ..writeln('```');
  final opened = <Thing>{};
  void tree(Thing t, int depth) {
    final pad = '  ' * depth;
    if (!opened.add(t)) {
      out.writeln('$pad${t.name} (above)');
      return;
    }
    out.writeln('$pad${t.name}');
    for (final child in widgetsUsedBy[t.path] ?? const <Thing>[]) {
      if (child != t) tree(child, depth + 1);
    }
  }

  for (final root in roots) {
    tree(root, 0);
  }
  out
    ..writeln('```')
    ..writeln()
    ..writeln('## Everything, by folder and file')
    ..writeln();

  final byFile = <String, List<Thing>>{};
  for (final t in things) {
    byFile.putIfAbsent(t.path, () => []).add(t);
  }
  String? lastFolder;
  for (final path in byFile.keys.toList()..sort()) {
    final folder = _folderOf(path);
    if (folder != lastFolder) {
      out
        ..writeln('### $folder')
        ..writeln();
      lastFolder = folder;
    }
    out.writeln('#### ${path.substring(4)}');
    for (final t in byFile[path]!) {
      out.writeln(
        '- **${t.name}** (${t.kind}, line ${t.line}): ${t.doc ?? '(no /// line)'}',
      );
      if (t.isRiverpod) out.writeln('  - read as `${t.usedAs}`');
      for (final take in t.takes) {
        out.writeln('  - takes `$take`');
      }
      if (t.has.isNotEmpty) out.writeln('  - has ${t.has.join(', ')}');
      final uses = usedIn[t]!;
      out.writeln(
        uses.isEmpty && t.kind == 'extension'
            ? '  - used in: not traced, extension members are called without its name'
            : '  - used in: ${_list(uses, lib: true)}',
      );
      if (testedIn[t]!.isNotEmpty) {
        out.writeln('  - tests: ${_list(testedIn[t], test: true)}');
      }
    }
    out.writeln();
  }

  final sorted = [...things]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  out
    ..writeln('## A to Z')
    ..writeln();
  for (final t in sorted) {
    out.writeln('- ${t.name}, ${t.kind}: ${t.path}:${t.line}');
  }

  final alone = [
    for (final t in sorted)
      if (usedIn[t]!.isEmpty && t.kind != 'extension' && t.name != 'main') t,
  ];
  out
    ..writeln()
    ..writeln('## Not used outside their own file')
    ..writeln()
    ..writeln(
      'Each of these is either used only where it is written, so it could '
      'be private, or not used at all and could go.',
    )
    ..writeln();
  for (final t in alone) {
    final tested = testedIn[t]!.isNotEmpty ? ' (tests use it)' : '';
    out.writeln('- ${t.name}, ${t.kind}: ${t.path}:${t.line}$tested');
  }

  return CodeMap(out.toString(), problems);
}

String _folderOf(String path) => path.substring(0, path.lastIndexOf('/'));

String _list(
  Iterable<String>? items, {
  bool short = false,
  bool lib = false,
  bool test = false,
}) {
  if (items == null || items.isEmpty) return 'nothing else';
  String trim(String p) {
    if (short) return p == 'lib' ? 'lib' : p.substring(4);
    if (lib) return p.substring(4);
    if (test && p.startsWith('test/')) return p.substring(5);
    return p;
  }

  return (items.map(trim).toList()..sort()).join(', ');
}

String _flat(String source) => source.replaceAll(RegExp(r'\s+'), ' ');

String? _docOf(AnnotatedNode node) {
  final comment = node.documentationComment;
  if (comment == null) return null;
  final lines = [
    for (final token in comment.tokens)
      token.lexeme.replaceFirst(RegExp(r'^///\s?'), '').trim(),
  ];
  final blank = lines.indexOf('');
  final first = blank == -1 ? lines : lines.sublist(0, blank);
  final text = first.join(' ').trim();
  return text.isEmpty ? null : text;
}

bool _isRiverpod(AnnotatedNode node) => node.metadata.any((a) {
  final name = a.name.name;
  return name == 'riverpod' || name == 'Riverpod';
});

bool _isPublic(String name) => !name.startsWith('_');

bool _isOverride(AnnotatedNode node) =>
    node.metadata.any((a) => a.name.name == 'override');

List<Thing> _readThings(String path, CompilationUnit unit, LineInfo lines) {
  int lineOf(AnnotatedNode node) => lines
      .getLocation(node.firstTokenAfterCommentAndMetadata.offset)
      .lineNumber;
  final found = <Thing>[];

  void add(
    AnnotatedNode node,
    String name,
    String kind, {
    String? superclass,
    List<String> takes = const [],
    List<String> has = const [],
  }) {
    if (!_isPublic(name)) return;
    found.add(
      Thing(
        name: name,
        kind: kind,
        path: path,
        line: lineOf(node),
        doc: _docOf(node),
        superclass: superclass,
        isRiverpod: _isRiverpod(node),
        takes: takes,
        has: has,
      ),
    );
  }

  for (final member in unit.declarations) {
    switch (member) {
      case ClassDeclaration():
        final name = member.namePart.typeName.lexeme;
        final superclass = member.extendsClause?.superclass.name.lexeme;
        final riverpod = _isRiverpod(member);
        final modifier = member.sealedKeyword != null
            ? 'sealed class'
            : member.abstractKeyword != null
            ? 'abstract class'
            : 'class';
        add(
          member,
          name,
          riverpod
              ? 'provider'
              : superclass == 'CustomPainter'
              ? 'painter'
              : modifier,
          superclass: superclass,
          takes: _constructors(name, member.body.members),
          has: _members(member.body.members),
        );
      case MixinDeclaration():
        add(
          member,
          member.name.lexeme,
          'mixin',
          has: _members(member.body.members),
        );
      case EnumDeclaration():
        add(
          member,
          member.namePart.typeName.lexeme,
          'enum',
          has: [
            'values ${member.body.constants.map((c) => c.name.lexeme).join(', ')}',
            ..._members(member.body.members),
          ],
        );
      case ExtensionTypeDeclaration():
        add(
          member,
          member.namePart.typeName.lexeme,
          'extension type',
          has: _members(member.body.members),
        );
      case ExtensionDeclaration():
        final name = member.name?.lexeme;
        if (name == null) break;
        add(
          member,
          name,
          'extension',
          has: [
            if (member.onClause case final on?)
              'on `${_flat(on.extendedType.toSource())}`',
            ..._members(member.body.members),
          ],
        );
      case TypeAlias():
        add(member, member.name.lexeme, 'typedef');
      case FunctionDeclaration():
        final name = member.name.lexeme;
        final returns = member.returnType == null
            ? ''
            : ', returns ${_flat(member.returnType!.toSource())}';
        final params = member.functionExpression.parameters;
        add(
          member,
          name,
          _isRiverpod(member)
              ? 'provider'
              : member.isGetter
              ? 'getter'
              : 'function',
          takes: [
            if (params != null)
              // a provider's Ref is passed by riverpod, never by the caller
              '${_params(params, const {}).replaceFirst(RegExp(r'^\(Ref ref(, |(?=\)))'), '(')}$returns'
            else if (returns.isNotEmpty)
              returns.substring(2),
          ],
        );
      case TopLevelVariableDeclaration():
        final list = member.variables;
        for (final v in list.variables) {
          final name = v.name.lexeme;
          add(
            member,
            name,
            name.endsWith('Provider')
                ? 'provider'
                : list.isConst
                ? 'constant'
                : 'value',
            takes: [
              if (list.type case final type?) 'type ${_flat(type.toSource())}',
            ],
          );
        }
      default:
        break;
    }
  }
  return found;
}

/// A class is a widget when it extends a Flutter widget base or another
/// widget in lib/.
void _markWidgets(List<Thing> things) {
  final widgets = <String>{..._widgetBases};
  var grew = true;
  while (grew) {
    grew = false;
    for (final t in things) {
      if (t.kind.endsWith('class') &&
          t.superclass != null &&
          widgets.contains(t.superclass) &&
          widgets.add(t.name)) {
        grew = true;
      }
    }
  }
  for (final t in things) {
    if (t.kind.endsWith('class') && widgets.contains(t.name)) {
      t.kind = 'widget';
      t.has = const [];
    }
  }
}

List<String> _constructors(String className, NodeList<ClassMember> members) {
  final fieldTypes = <String, String>{};
  for (final m in members) {
    if (m is FieldDeclaration) {
      for (final v in m.fields.variables) {
        fieldTypes[v.name.lexeme] = m.fields.type == null
            ? 'var'
            : _flat(m.fields.type!.toSource());
      }
    }
  }
  return [
    for (final m in members)
      if (m is ConstructorDeclaration && _isPublic(m.name?.lexeme ?? ''))
        '$className${m.name == null ? '' : '.${m.name!.lexeme}'}'
            '${_params(m.parameters, fieldTypes)}',
  ];
}

String _params(FormalParameterList list, Map<String, String> fieldTypes) {
  final positional = <String>[];
  final optional = <String>[];
  final named = <String>[];
  for (final p in list.parameters) {
    final name = p.name?.lexeme ?? '';
    if (p is SuperFormalParameter && name == 'key') continue;
    String text;
    if (p.functionTypedSuffix != null) {
      text = _flat(p.toSource());
    } else {
      final type = p.type != null
          ? _flat(p.type!.toSource())
          : p is FieldFormalParameter
          ? fieldTypes[name]
          : null;
      final required = p.isRequiredNamed ? 'required ' : '';
      final value = p.defaultClause?.value.toSource();
      final fallback = value != null && value.length <= 24 ? ' = $value' : '';
      text = '$required${type == null ? '' : '$type '}$name$fallback';
    }
    if (p.isNamed) {
      named.add(text);
    } else if (p.isOptionalPositional) {
      optional.add(text);
    } else {
      positional.add(text);
    }
  }
  return '(${[...positional, if (optional.isNotEmpty) '[${optional.join(', ')}]', if (named.isNotEmpty) '{${named.join(', ')}}'].join(', ')})';
}

List<String> _members(NodeList<ClassMember> members) => [
  for (final m in members)
    if (m is MethodDeclaration &&
        _isPublic(m.name.lexeme) &&
        !_isOverride(m) &&
        !m.isSetter)
      m.isGetter ? m.name.lexeme : '${m.name.lexeme}()'
    else if (m is FieldDeclaration && !_isOverride(m))
      for (final v in m.fields.variables)
        if (_isPublic(v.name.lexeme)) v.name.lexeme,
];

/// Every name a file writes, in the order it first appears. Comments and the
/// names declarations give themselves are left out.
LinkedHashSet<String> _namesIn(CompilationUnit unit) {
  final visitor = _NameCollector();
  unit.accept(visitor);
  return visitor.names;
}

class _NameCollector extends RecursiveAstVisitor<void> {
  final names = <String>{} as LinkedHashSet<String>;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    // a constructor writes its class name, which is not a use
    if (parent is ConstructorDeclaration && parent.typeName == node) return;
    names.add(node.name);
  }

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitComment(Comment node) {}
}

typedef _Links = ({Set<String> imports, Set<String> exports});

/// The repo files a file imports and exports. Packages are left out.
_Links _linksOf(String path, CompilationUnit unit) {
  String? resolve(NamespaceDirective d) {
    final uri = d.uri.stringValue;
    if (uri == null) return null;
    if (uri.startsWith('package:konsou/')) {
      return 'lib/${uri.substring('package:konsou/'.length)}';
    }
    if (uri.contains(':')) return null;
    return Uri.parse(path).resolve(uri).path;
  }

  return (
    imports: {
      for (final d in unit.directives.whereType<ImportDirective>()) ?resolve(d),
    },
    exports: {
      for (final d in unit.directives.whereType<ExportDirective>()) ?resolve(d),
    },
  );
}

Map<String, String> _dartFiles(String root, {bool skipGenerated = false}) {
  final dir = Directory(root);
  if (!dir.existsSync()) return {};
  return {
    for (final f in dir.listSync(recursive: true))
      if (f is File &&
          f.path.endsWith('.dart') &&
          !(skipGenerated && f.path.endsWith('.g.dart')))
        f.path.replaceAll('\\', '/'): f.readAsStringSync(),
  };
}

/// Reads lib/, test/ and integration_test/, writes CODE_MAP.md and returns
/// what check should fail on.
List<String> writeCodeMap() {
  final map = buildCodeMap(_dartFiles('lib', skipGenerated: true), {
    ..._dartFiles('test'),
    ..._dartFiles('integration_test'),
  });
  File(codeMapPath).writeAsStringSync(map.markdown);
  return map.problems;
}

/// Writes the map on its own, without the other gates.
void main() {
  final problems = writeCodeMap();
  for (final p in problems) {
    stdout.writeln(p);
  }
  stdout.writeln(
    problems.isEmpty
        ? 'Wrote $codeMapPath.'
        : 'Wrote $codeMapPath with ${problems.length} problem(s).',
  );
  exitCode = problems.isEmpty ? 0 : 1;
}
