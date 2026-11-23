// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickSearch)
final quickSearchProvider = QuickSearchProvider._();

final class QuickSearchProvider
    extends $NotifierProvider<QuickSearch, QuickState> {
  QuickSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickSearchHash();

  @$internal
  @override
  QuickSearch create() => QuickSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickState>(value),
    );
  }
}

String _$quickSearchHash() => r'b7a0244b9bfa23b1041403425e21107e4906f49e';

abstract class _$QuickSearch extends $Notifier<QuickState> {
  QuickState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuickState, QuickState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickState, QuickState>,
              QuickState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
