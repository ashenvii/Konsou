// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A title page's data, refetched from MAL when stale and reloaded on edits.

@ProviderFor(DetailPage)
final detailPageProvider = DetailPageFamily._();

/// A title page's data, refetched from MAL when stale and reloaded on edits.
final class DetailPageProvider
    extends $AsyncNotifierProvider<DetailPage, DetailPageData> {
  /// A title page's data, refetched from MAL when stale and reloaded on edits.
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

String _$detailPageHash() => r'18739c8ea4e4e4912988549ecdc4f7d9ec598b82';

/// A title page's data, refetched from MAL when stale and reloaded on edits.

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

  /// A title page's data, refetched from MAL when stale and reloaded on edits.

  DetailPageProvider call(int malId, {String? entryId}) =>
      DetailPageProvider._(argument: (malId, entryId: entryId), from: this);

  @override
  String toString() => r'detailPageProvider';
}

/// A title page's data, refetched from MAL when stale and reloaded on edits.

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

/// The watch order of the franchise a title belongs to.

@ProviderFor(watchOrder)
final watchOrderProvider = WatchOrderFamily._();

/// The watch order of the franchise a title belongs to.

final class WatchOrderProvider
    extends
        $FunctionalProvider<
          AsyncValue<WatchOrder>,
          WatchOrder,
          FutureOr<WatchOrder>
        >
    with $FutureModifier<WatchOrder>, $FutureProvider<WatchOrder> {
  /// The watch order of the franchise a title belongs to.
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

String _$watchOrderHash() => r'8f06ed4f8664a2e7fd4f7b36c2c0da8fc6cb1ef5';

/// The watch order of the franchise a title belongs to.

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

  /// The watch order of the franchise a title belongs to.

  WatchOrderProvider call(int malId) =>
      WatchOrderProvider._(argument: malId, from: this);

  @override
  String toString() => r'watchOrderProvider';
}

/// The titles MAL's users recommend after [malId], with what is saved of
/// each; the cards fetch the rest while they show.

@ProviderFor(recommendedTitles)
final recommendedTitlesProvider = RecommendedTitlesFamily._();

/// The titles MAL's users recommend after [malId], with what is saved of
/// each; the cards fetch the rest while they show.

final class RecommendedTitlesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecommendedTitle>>,
          List<RecommendedTitle>,
          FutureOr<List<RecommendedTitle>>
        >
    with
        $FutureModifier<List<RecommendedTitle>>,
        $FutureProvider<List<RecommendedTitle>> {
  /// The titles MAL's users recommend after [malId], with what is saved of
  /// each; the cards fetch the rest while they show.
  RecommendedTitlesProvider._({
    required RecommendedTitlesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recommendedTitlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recommendedTitlesHash();

  @override
  String toString() {
    return r'recommendedTitlesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RecommendedTitle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecommendedTitle>> create(Ref ref) {
    final argument = this.argument as int;
    return recommendedTitles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendedTitlesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recommendedTitlesHash() => r'4a24649388814d7f284cfab4cf2815ffd10e247f';

/// The titles MAL's users recommend after [malId], with what is saved of
/// each; the cards fetch the rest while they show.

final class RecommendedTitlesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RecommendedTitle>>, int> {
  RecommendedTitlesFamily._()
    : super(
        retry: null,
        name: r'recommendedTitlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The titles MAL's users recommend after [malId], with what is saved of
  /// each; the cards fetch the rest while they show.

  RecommendedTitlesProvider call(int malId) =>
      RecommendedTitlesProvider._(argument: malId, from: this);

  @override
  String toString() => r'recommendedTitlesProvider';
}

/// A not linked entry and its suggested pages, reloaded when either changes.

@ProviderFor(notLinkedPage)
final notLinkedPageProvider = NotLinkedPageFamily._();

/// A not linked entry and its suggested pages, reloaded when either changes.

final class NotLinkedPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotLinkedPage>,
          NotLinkedPage,
          FutureOr<NotLinkedPage>
        >
    with $FutureModifier<NotLinkedPage>, $FutureProvider<NotLinkedPage> {
  /// A not linked entry and its suggested pages, reloaded when either changes.
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

/// A not linked entry and its suggested pages, reloaded when either changes.

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

  /// A not linked entry and its suggested pages, reloaded when either changes.

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

String _$pickerSearchHash() => r'c74b870a4baf91a497fd4634cead18bd1c46e9c9';

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
