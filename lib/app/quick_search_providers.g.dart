// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Quick search's state and actions: open, type, page, move focus, open a row.

@ProviderFor(QuickSearch)
final quickSearchProvider = QuickSearchProvider._();

/// Quick search's state and actions: open, type, page, move focus, open a row.
final class QuickSearchProvider
    extends $NotifierProvider<QuickSearch, QuickState> {
  /// Quick search's state and actions: open, type, page, move focus, open a row.
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

String _$quickSearchHash() => r'095d2b346f423e91d13e6087e4ed08bd1b204a55';

/// Quick search's state and actions: open, type, page, move focus, open a row.

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
