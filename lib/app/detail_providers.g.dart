// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DetailPage)
final detailPageProvider = DetailPageFamily._();

final class DetailPageProvider
    extends $AsyncNotifierProvider<DetailPage, DetailPageData> {
  DetailPageProvider._({
    required DetailPageFamily super.from,
    required (int, {String? entryId}) super.argument,
  }) : super(
         retry: null,
         name: r'detailPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailPageHash();

  @override
  String toString() {
    return r'detailPageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DetailPage create() => DetailPage();

  @override
  bool operator ==(Object other) {
    return other is DetailPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailPageHash() => r'92e25f5e0cef07e232a5467dac078aecf781503a';

final class DetailPageFamily extends $Family
    with
        $ClassFamilyOverride<
          DetailPage,
          AsyncValue<DetailPageData>,
          DetailPageData,
          FutureOr<DetailPageData>,
          (int, {String? entryId})
        > {
  DetailPageFamily._()
    : super(
        retry: null,
        name: r'detailPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DetailPageProvider call(int malId, {String? entryId}) =>
      DetailPageProvider._(argument: (malId, entryId: entryId), from: this);

  @override
  String toString() => r'detailPageProvider';
}

abstract class _$DetailPage extends $AsyncNotifier<DetailPageData> {
  late final _$args = ref.$arg as (int, {String? entryId});
  int get malId => _$args.$1;
  String? get entryId => _$args.entryId;

  FutureOr<DetailPageData> build(int malId, {String? entryId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DetailPageData>, DetailPageData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DetailPageData>, DetailPageData>,
              AsyncValue<DetailPageData>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, entryId: _$args.entryId),
    );
  }
}

@ProviderFor(watchOrder)
final watchOrderProvider = WatchOrderFamily._();

final class WatchOrderProvider
    extends
        $FunctionalProvider<
          AsyncValue<WatchOrder>,
          WatchOrder,
          FutureOr<WatchOrder>
        >
    with $FutureModifier<WatchOrder>, $FutureProvider<WatchOrder> {
  WatchOrderProvider._({
    required WatchOrderFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'watchOrderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchOrderHash();

  @override
  String toString() {
    return r'watchOrderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WatchOrder> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WatchOrder> create(Ref ref) {
    final argument = this.argument as int;
    return watchOrder(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchOrderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchOrderHash() => r'64ec31bf492382827a98d0b04e065115213c8944';

final class WatchOrderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WatchOrder>, int> {
  WatchOrderFamily._()
    : super(
        retry: null,
        name: r'watchOrderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchOrderProvider call(int malId) =>
      WatchOrderProvider._(argument: malId, from: this);

  @override
  String toString() => r'watchOrderProvider';
}

@ProviderFor(notLinkedPage)
final notLinkedPageProvider = NotLinkedPageFamily._();

final class NotLinkedPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotLinkedPage>,
          NotLinkedPage,
          FutureOr<NotLinkedPage>
        >
    with $FutureModifier<NotLinkedPage>, $FutureProvider<NotLinkedPage> {
  NotLinkedPageProvider._({
    required NotLinkedPageFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'notLinkedPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notLinkedPageHash();

  @override
  String toString() {
    return r'notLinkedPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NotLinkedPage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotLinkedPage> create(Ref ref) {
    final argument = this.argument as String;
    return notLinkedPage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotLinkedPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notLinkedPageHash() => r'c141e0663475bf324f1fa7ce1a6bff24e18d8853';

final class NotLinkedPageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NotLinkedPage>, String> {
  NotLinkedPageFamily._()
    : super(
        retry: null,
        name: r'notLinkedPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NotLinkedPageProvider call(String entryId) =>
      NotLinkedPageProvider._(argument: entryId, from: this);

  @override
  String toString() => r'notLinkedPageProvider';
}

/// The entries Konsou is looking up a page for right now, so their picker
/// can say so in place of "No suggestions".

@ProviderFor(LookingForPage)
final lookingForPageProvider = LookingForPageProvider._();

/// The entries Konsou is looking up a page for right now, so their picker
/// can say so in place of "No suggestions".
final class LookingForPageProvider
    extends $NotifierProvider<LookingForPage, Set<String>> {
  /// The entries Konsou is looking up a page for right now, so their picker
  /// can say so in place of "No suggestions".
  LookingForPageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lookingForPageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lookingForPageHash();

  @$internal
  @override
  LookingForPage create() => LookingForPage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$lookingForPageHash() => r'207a732460fab3953d693349c45a11155bdd9d5a';

/// The entries Konsou is looking up a page for right now, so their picker
/// can say so in place of "No suggestions".

abstract class _$LookingForPage extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Null when no connection to MAL is set up, so nothing can be linked.

@ProviderFor(pageLinking)
final pageLinkingProvider = PageLinkingProvider._();

/// Null when no connection to MAL is set up, so nothing can be linked.

final class PageLinkingProvider
    extends $FunctionalProvider<PageLinking?, PageLinking?, PageLinking?>
    with $Provider<PageLinking?> {
  /// Null when no connection to MAL is set up, so nothing can be linked.
  PageLinkingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageLinkingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageLinkingHash();

  @$internal
  @override
  $ProviderElement<PageLinking?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PageLinking? create(Ref ref) {
    return pageLinking(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageLinking? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageLinking?>(value),
    );
  }
}

String _$pageLinkingHash() => r'f2c0af4fea75dc63ddc6656f43d31ded0ec2dd8f';

/// The page picker's search box: the typed MAL search with the typo help.

@ProviderFor(PickerSearch)
final pickerSearchProvider = PickerSearchFamily._();

/// The page picker's search box: the typed MAL search with the typo help.
final class PickerSearchProvider
    extends $NotifierProvider<PickerSearch, PickerSearchState> {
  /// The page picker's search box: the typed MAL search with the typo help.
  PickerSearchProvider._({
    required PickerSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pickerSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pickerSearchHash();

  @override
  String toString() {
    return r'pickerSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PickerSearch create() => PickerSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickerSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickerSearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PickerSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pickerSearchHash() => r'84dfea5afb9b60b04e9f235bfaf85d4eb42ac720';

/// The page picker's search box: the typed MAL search with the typo help.

final class PickerSearchFamily extends $Family
    with
        $ClassFamilyOverride<
          PickerSearch,
          PickerSearchState,
          PickerSearchState,
          PickerSearchState,
          String
        > {
  PickerSearchFamily._()
    : super(
        retry: null,
        name: r'pickerSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The page picker's search box: the typed MAL search with the typo help.

  PickerSearchProvider call(String entryId) =>
      PickerSearchProvider._(argument: entryId, from: this);

  @override
  String toString() => r'pickerSearchProvider';
}

/// The page picker's search box: the typed MAL search with the typo help.

abstract class _$PickerSearch extends $Notifier<PickerSearchState> {
  late final _$args = ref.$arg as String;
  String get entryId => _$args;

  PickerSearchState build(String entryId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PickerSearchState, PickerSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PickerSearchState, PickerSearchState>,
              PickerSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
