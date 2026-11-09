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
