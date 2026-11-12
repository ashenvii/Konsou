// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(services)
final servicesProvider = ServicesProvider._();

final class ServicesProvider
    extends $FunctionalProvider<Services, Services, Services>
    with $Provider<Services> {
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

@ProviderFor(coverStore)
final coverStoreProvider = CoverStoreProvider._();

final class CoverStoreProvider
    extends $FunctionalProvider<CoverStore?, CoverStore?, CoverStore?>
    with $Provider<CoverStore?> {
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

@ProviderFor(coverSaved)
final coverSavedProvider = CoverSavedProvider._();

final class CoverSavedProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  CoverSavedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coverSavedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coverSavedHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return coverSaved(ref);
  }
}

String _$coverSavedHash() => r'c327a734ca2863986a60f0b3390a385cb5cb8b3d';

@ProviderFor(KeptCovers)
final keptCoversProvider = KeptCoversProvider._();

final class KeptCoversProvider
    extends $AsyncNotifierProvider<KeptCovers, Map<(int, CoverSize), File>> {
  KeptCoversProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keptCoversProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keptCoversHash();

  @$internal
  @override
  KeptCovers create() => KeptCovers();
}

String _$keptCoversHash() => r'ad7bac2b0120ec5c098da6cc44f413e2ec9288a9';

abstract class _$KeptCovers
    extends $AsyncNotifier<Map<(int, CoverSize), File>> {
  FutureOr<Map<(int, CoverSize), File>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<(int, CoverSize), File>>,
              Map<(int, CoverSize), File>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<(int, CoverSize), File>>,
                Map<(int, CoverSize), File>
              >,
              AsyncValue<Map<(int, CoverSize), File>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(coverFile)
final coverFileProvider = CoverFileFamily._();

final class CoverFileProvider
    extends $FunctionalProvider<AsyncValue<File?>, File?, FutureOr<File?>>
    with $FutureModifier<File?>, $FutureProvider<File?> {
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

String _$coverFileHash() => r'060c598c943205529d098e5b1963d6b016aebcb7';

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

  CoverFileProvider call(int malId, CoverSize size) =>
      CoverFileProvider._(argument: (malId, size), from: this);

  @override
  String toString() => r'coverFileProvider';
}

@ProviderFor(detailOnScreen)
final detailOnScreenProvider = DetailOnScreenFamily._();

final class DetailOnScreenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  DetailOnScreenProvider._({
    required DetailOnScreenFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'detailOnScreenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailOnScreenHash();

  @override
  String toString() {
    return r'detailOnScreenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as int;
    return detailOnScreen(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DetailOnScreenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailOnScreenHash() => r'ce4c28b396a96dbd2de8fd4b489d0dc71c3cfc48';

final class DetailOnScreenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, int> {
  DetailOnScreenFamily._()
    : super(
        retry: null,
        name: r'detailOnScreenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DetailOnScreenProvider call(int malId) =>
      DetailOnScreenProvider._(argument: malId, from: this);

  @override
  String toString() => r'detailOnScreenProvider';
}
