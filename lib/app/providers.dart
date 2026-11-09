import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'services.dart';

part 'providers.g.dart';

/// The background work and the databases, built once at launch. `main`
/// overrides it with the real thing; screens read the databases through it.
@Riverpod(keepAlive: true)
Services services(Ref ref) => throw UnimplementedError('override in main');
