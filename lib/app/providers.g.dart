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

/// Opens a link in the user's browser, for a screen's links out.

@ProviderFor(openLink)
final openLinkProvider = OpenLinkProvider._();

/// Opens a link in the user's browser, for a screen's links out.

final class OpenLinkProvider
    extends
        $FunctionalProvider<
          Future<void> Function(Uri url),
          Future<void> Function(Uri url),
          Future<void> Function(Uri url)
        >
    with $Provider<Future<void> Function(Uri url)> {
  /// Opens a link in the user's browser, for a screen's links out.
  OpenLinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openLinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openLinkHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function(Uri url)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function(Uri url) create(Ref ref) {
    return openLink(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function(Uri url) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<void> Function(Uri url)>(
        value,
      ),
    );
  }
}

String _$openLinkHash() => r'5e394f335dccc48a652b2837620c8e49bd4906bb';

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
    required (int, CoverSize, {String? pictureUrl, Lane lane}) super.argument,
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
    final argument =
        this.argument as (int, CoverSize, {String? pictureUrl, Lane lane});
    return coverFile(
      ref,
      argument.$1,
      argument.$2,
      pictureUrl: argument.pictureUrl,
      lane: argument.lane,
    );
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

String _$coverFileHash() => r'c8f1437c78cd6f1328e6c6cc7cc33c7f6f68280f';

final class CoverFileFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<File?>,
          (int, CoverSize, {String? pictureUrl, Lane lane})
        > {
  CoverFileFamily._()
    : super(
        retry: null,
        name: r'coverFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CoverFileProvider call(
    int malId,
    CoverSize size, {
    String? pictureUrl,
    Lane lane = Lane.screen,
  }) => CoverFileProvider._(
    argument: (malId, size, pictureUrl: pictureUrl, lane: lane),
    from: this,
  );

  @override
  String toString() => r'coverFileProvider';
}

/// One of MAL's extra pictures of a title, kept for the last few titles.

@ProviderFor(titlePicture)
final titlePictureProvider = TitlePictureFamily._();

/// One of MAL's extra pictures of a title, kept for the last few titles.

final class TitlePictureProvider
    extends $FunctionalProvider<AsyncValue<File?>, File?, FutureOr<File?>>
    with $FutureModifier<File?>, $FutureProvider<File?> {
  /// One of MAL's extra pictures of a title, kept for the last few titles.
  TitlePictureProvider._({
    required TitlePictureFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'titlePictureProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$titlePictureHash();

  @override
  String toString() {
    return r'titlePictureProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<File?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<File?> create(Ref ref) {
    final argument = this.argument as (int, String);
    return titlePicture(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TitlePictureProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$titlePictureHash() => r'94512df4055911c3fd2519f8fba4e2ea64c312b9';

/// One of MAL's extra pictures of a title, kept for the last few titles.

final class TitlePictureFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<File?>, (int, String)> {
  TitlePictureFamily._()
    : super(
        retry: null,
        name: r'titlePictureProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One of MAL's extra pictures of a title, kept for the last few titles.

  TitlePictureProvider call(int malId, String url) =>
      TitlePictureProvider._(argument: (malId, url), from: this);

  @override
  String toString() => r'titlePictureProvider';
}

@ProviderFor(detailOnScreen)
final detailOnScreenProvider = DetailOnScreenFamily._();

final class DetailOnScreenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  DetailOnScreenProvider._({
    required DetailOnScreenFamily super.from,
    required (int, {Lane lane}) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (int, {Lane lane});
    return detailOnScreen(ref, argument.$1, lane: argument.lane);
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

String _$detailOnScreenHash() => r'8a83f5cc75b22cf8803adb0726bdd1abcc95f218';

final class DetailOnScreenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (int, {Lane lane})> {
  DetailOnScreenFamily._()
    : super(
        retry: null,
        name: r'detailOnScreenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DetailOnScreenProvider call(int malId, {Lane lane = Lane.screen}) =>
      DetailOnScreenProvider._(argument: (malId, lane: lane), from: this);

  @override
  String toString() => r'detailOnScreenProvider';
}

/// The large cover of a title, kept or fetched.

@ProviderFor(largeCover)
final largeCoverProvider = LargeCoverFamily._();

/// The large cover of a title, kept or fetched.

final class LargeCoverProvider
    extends $FunctionalProvider<AsyncValue<File?>, File?, FutureOr<File?>>
    with $FutureModifier<File?>, $FutureProvider<File?> {
  /// The large cover of a title, kept or fetched.
  LargeCoverProvider._({
    required LargeCoverFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'largeCoverProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$largeCoverHash();

  @override
  String toString() {
    return r'largeCoverProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<File?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<File?> create(Ref ref) {
    final argument = this.argument as int;
    return largeCover(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LargeCoverProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$largeCoverHash() => r'97d3ae5f373a43911bca65e4436838b83bccb1a6';

/// The large cover of a title, kept or fetched.

final class LargeCoverFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<File?>, int> {
  LargeCoverFamily._()
    : super(
        retry: null,
        name: r'largeCoverProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The large cover of a title, kept or fetched.

  LargeCoverProvider call(int malId) =>
      LargeCoverProvider._(argument: malId, from: this);

  @override
  String toString() => r'largeCoverProvider';
}

/// A picture file's size and detail per row, for cropping it to a box.

@ProviderFor(pictureLook)
final pictureLookProvider = PictureLookFamily._();

/// A picture file's size and detail per row, for cropping it to a box.

final class PictureLookProvider
    extends
        $FunctionalProvider<
          AsyncValue<PictureLook?>,
          PictureLook?,
          FutureOr<PictureLook?>
        >
    with $FutureModifier<PictureLook?>, $FutureProvider<PictureLook?> {
  /// A picture file's size and detail per row, for cropping it to a box.
  PictureLookProvider._({
    required PictureLookFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pictureLookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pictureLookHash();

  @override
  String toString() {
    return r'pictureLookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PictureLook?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PictureLook?> create(Ref ref) {
    final argument = this.argument as String;
    return pictureLook(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PictureLookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pictureLookHash() => r'3c2826547502505b065aa74ebc7e34d2939f192f';

/// A picture file's size and detail per row, for cropping it to a box.

final class PictureLookFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PictureLook?>, String> {
  PictureLookFamily._()
    : super(
        retry: null,
        name: r'pictureLookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A picture file's size and detail per row, for cropping it to a box.

  PictureLookProvider call(String path) =>
      PictureLookProvider._(argument: path, from: this);

  @override
  String toString() => r'pictureLookProvider';
}
