// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Library's rows, franchises folded. Reloads itself while the background
/// work saves details, matches and franchises. An edit reloads it at once with
/// `ref.invalidate`.

@ProviderFor(libraryRows)
final libraryRowsProvider = LibraryRowsProvider._();

/// The Library's rows, franchises folded. Reloads itself while the background
/// work saves details, matches and franchises. An edit reloads it at once with
/// `ref.invalidate`.

final class LibraryRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryRow>>,
          List<LibraryRow>,
          FutureOr<List<LibraryRow>>
        >
    with $FutureModifier<List<LibraryRow>>, $FutureProvider<List<LibraryRow>> {
  /// The Library's rows, franchises folded. Reloads itself while the background
  /// work saves details, matches and franchises. An edit reloads it at once with
  /// `ref.invalidate`.
  LibraryRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRowsHash();

  @$internal
  @override
  $FutureProviderElement<List<LibraryRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LibraryRow>> create(Ref ref) {
    return libraryRows(ref);
  }
}

String _$libraryRowsHash() => r'70e9493639bfda3a97b0872211ca6842461d06c4';

/// The edits a Library screen can make. Each one tells sync a change was made.

@ProviderFor(entryEdits)
final entryEditsProvider = EntryEditsProvider._();

/// The edits a Library screen can make. Each one tells sync a change was made.

final class EntryEditsProvider
    extends $FunctionalProvider<EntryEdits, EntryEdits, EntryEdits>
    with $Provider<EntryEdits> {
  /// The edits a Library screen can make. Each one tells sync a change was made.
  EntryEditsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryEditsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryEditsHash();

  @$internal
  @override
  $ProviderElement<EntryEdits> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EntryEdits create(Ref ref) {
    return entryEdits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntryEdits value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntryEdits>(value),
    );
  }
}

String _$entryEditsHash() => r'd4e22babeb247de727d6fa7a463b4446518ac353';

/// The tab the Library is on, kept while the app runs.

@ProviderFor(LibraryTabChoice)
final libraryTabChoiceProvider = LibraryTabChoiceProvider._();

/// The tab the Library is on, kept while the app runs.
final class LibraryTabChoiceProvider
    extends $NotifierProvider<LibraryTabChoice, LibraryTab> {
  /// The tab the Library is on, kept while the app runs.
  LibraryTabChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryTabChoiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryTabChoiceHash();

  @$internal
  @override
  LibraryTabChoice create() => LibraryTabChoice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryTab>(value),
    );
  }
}

String _$libraryTabChoiceHash() => r'8897f3d6db81c938b141cf99352ff6ae33d0eaba';

/// The tab the Library is on, kept while the app runs.

abstract class _$LibraryTabChoice extends $Notifier<LibraryTab> {
  LibraryTab build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LibraryTab, LibraryTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LibraryTab, LibraryTab>,
              LibraryTab,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The Library's sort, kept while the app runs.

@ProviderFor(LibrarySortChoice)
final librarySortChoiceProvider = LibrarySortChoiceProvider._();

/// The Library's sort, kept while the app runs.
final class LibrarySortChoiceProvider
    extends $NotifierProvider<LibrarySortChoice, LibrarySort> {
  /// The Library's sort, kept while the app runs.
  LibrarySortChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'librarySortChoiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$librarySortChoiceHash();

  @$internal
  @override
  LibrarySortChoice create() => LibrarySortChoice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibrarySort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibrarySort>(value),
    );
  }
}

String _$librarySortChoiceHash() => r'4bbe84d5bcd80a355f15722e80035eb093a8b206';

/// The Library's sort, kept while the app runs.

abstract class _$LibrarySortChoice extends $Notifier<LibrarySort> {
  LibrarySort build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LibrarySort, LibrarySort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LibrarySort, LibrarySort>,
              LibrarySort,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Grid or list, remembered on this device. Grid until the user picks.

@ProviderFor(LibraryLayoutChoice)
final libraryLayoutChoiceProvider = LibraryLayoutChoiceProvider._();

/// Grid or list, remembered on this device. Grid until the user picks.
final class LibraryLayoutChoiceProvider
    extends $AsyncNotifierProvider<LibraryLayoutChoice, LibraryLayout> {
  /// Grid or list, remembered on this device. Grid until the user picks.
  LibraryLayoutChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryLayoutChoiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryLayoutChoiceHash();

  @$internal
  @override
  LibraryLayoutChoice create() => LibraryLayoutChoice();
}

String _$libraryLayoutChoiceHash() =>
    r'54b2943451e1196c95249bcc997d462867f03615';

/// Grid or list, remembered on this device. Grid until the user picks.

abstract class _$LibraryLayoutChoice extends $AsyncNotifier<LibraryLayout> {
  FutureOr<LibraryLayout> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LibraryLayout>, LibraryLayout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LibraryLayout>, LibraryLayout>,
              AsyncValue<LibraryLayout>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
