// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The background work and the databases, built once at launch. `main`
/// overrides it with the real thing; screens read the databases through it.

@ProviderFor(services)
final servicesProvider = ServicesProvider._();

/// The background work and the databases, built once at launch. `main`
/// overrides it with the real thing; screens read the databases through it.

final class ServicesProvider
    extends $FunctionalProvider<Services, Services, Services>
    with $Provider<Services> {
  /// The background work and the databases, built once at launch. `main`
  /// overrides it with the real thing; screens read the databases through it.
  ServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicesHash();

  @$internal
  @override
  $ProviderElement<Services> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Services create(Ref ref) {
    return services(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Services value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Services>(value),
    );
  }
}

String _$servicesHash() => r'1afb2ccdfe0ef5053954a999d779b484975b6ed4';

/// Null when no MAL client ID was built in, so no covers can be fetched.

@ProviderFor(coverStore)
final coverStoreProvider = CoverStoreProvider._();

/// Null when no MAL client ID was built in, so no covers can be fetched.

final class CoverStoreProvider
    extends $FunctionalProvider<CoverStore?, CoverStore?, CoverStore?>
    with $Provider<CoverStore?> {
  /// Null when no MAL client ID was built in, so no covers can be fetched.
  CoverStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coverStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coverStoreHash();

  @$internal
  @override
  $ProviderElement<CoverStore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoverStore? create(Ref ref) {
    return coverStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoverStore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoverStore?>(value),
    );
  }
}

String _$coverStoreHash() => r'23429bac3b1807ecb78efaeef448c14e9d28e935';

/// A cover's file: kept on the device, or fetched now ahead of the background
/// trickle. Null while the title has no details or no picture, or offline.

@ProviderFor(coverFile)
final coverFileProvider = CoverFileFamily._();

/// A cover's file: kept on the device, or fetched now ahead of the background
/// trickle. Null while the title has no details or no picture, or offline.

final class CoverFileProvider
    extends $FunctionalProvider<AsyncValue<File?>, File?, FutureOr<File?>>
    with $FutureModifier<File?>, $FutureProvider<File?> {
  /// A cover's file: kept on the device, or fetched now ahead of the background
  /// trickle. Null while the title has no details or no picture, or offline.
  CoverFileProvider._({
    required CoverFileFamily super.from,
    required (int, CoverSize) super.argument,
  }) : super(
         retry: null,
         name: r'coverFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coverFileHash();

  @override
  String toString() {
    return r'coverFileProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<File?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<File?> create(Ref ref) {
    final argument = this.argument as (int, CoverSize);
    return coverFile(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CoverFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coverFileHash() => r'2630a843b33d886655f352ae91324147358e499b';

/// A cover's file: kept on the device, or fetched now ahead of the background
/// trickle. Null while the title has no details or no picture, or offline.

final class CoverFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<File?>, (int, CoverSize)> {
  CoverFileFamily._()
    : super(
        retry: null,
        name: r'coverFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A cover's file: kept on the device, or fetched now ahead of the background
  /// trickle. Null while the title has no details or no picture, or offline.

  CoverFileProvider call(int malId, CoverSize size) =>
      CoverFileProvider._(argument: (malId, size), from: this);

  @override
  String toString() => r'coverFileProvider';
}
