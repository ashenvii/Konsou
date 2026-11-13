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

String _$detailPageHash() => r'4825351775e8fbf34e4fb5ae26c1fc7f83f16076';

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

String _$notLinkedPageHash() => r'539dad588046947fe24ecb4d8ba10094efa5a98b';

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
