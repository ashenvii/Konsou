// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryRows)
final libraryRowsProvider = LibraryRowsProvider._();

final class LibraryRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryRow>>,
          List<LibraryRow>,
          FutureOr<List<LibraryRow>>
        >
    with $FutureModifier<List<LibraryRow>>, $FutureProvider<List<LibraryRow>> {
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

String _$libraryRowsHash() => r'0b2dc0024a643b06083371e9e1125971f3321bb1';

@ProviderFor(entryEdits)
final entryEditsProvider = EntryEditsProvider._();

final class EntryEditsProvider
    extends $FunctionalProvider<EntryEdits, EntryEdits, EntryEdits>
    with $Provider<EntryEdits> {
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

@ProviderFor(entryActions)
final entryActionsProvider = EntryActionsProvider._();

final class EntryActionsProvider
    extends $FunctionalProvider<EntryActions, EntryActions, EntryActions>
    with $Provider<EntryActions> {
  EntryActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryActionsHash();

  @$internal
  @override
  $ProviderElement<EntryActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EntryActions create(Ref ref) {
    return entryActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntryActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntryActions>(value),
    );
  }
}

String _$entryActionsHash() => r'c9c74ba5954903ae3c1928f81bc38e0af79fdd37';

@ProviderFor(LibraryTabChoice)
final libraryTabChoiceProvider = LibraryTabChoiceProvider._();

final class LibraryTabChoiceProvider
    extends $NotifierProvider<LibraryTabChoice, LibraryTab> {
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

String _$libraryTabChoiceHash() => r'71e48f51518353c8c0d421a05b435cd8a2708faa';

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

@ProviderFor(LibraryKept)
final libraryKeptProvider = LibraryKeptProvider._();

final class LibraryKeptProvider
    extends $NotifierProvider<LibraryKept, Set<String>> {
  LibraryKeptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryKeptProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryKeptHash();

  @$internal
  @override
  LibraryKept create() => LibraryKept();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$libraryKeptHash() => r'f023d053fbfd5f5d282c9a21a7ef79165249b97a';

abstract class _$LibraryKept extends $Notifier<Set<String>> {
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

@ProviderFor(LibraryFindChoice)
final libraryFindChoiceProvider = LibraryFindChoiceProvider._();

final class LibraryFindChoiceProvider
    extends $NotifierProvider<LibraryFindChoice, String?> {
  LibraryFindChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryFindChoiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryFindChoiceHash();

  @$internal
  @override
  LibraryFindChoice create() => LibraryFindChoice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$libraryFindChoiceHash() => r'49e6c3fdb83d17a0f6a251c180ff702c1e0e668b';

abstract class _$LibraryFindChoice extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(entrySearch)
final entrySearchProvider = EntrySearchProvider._();

final class EntrySearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<EntrySearch>,
          EntrySearch,
          FutureOr<EntrySearch>
        >
    with $FutureModifier<EntrySearch>, $FutureProvider<EntrySearch> {
  EntrySearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entrySearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entrySearchHash();

  @$internal
  @override
  $FutureProviderElement<EntrySearch> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EntrySearch> create(Ref ref) {
    return entrySearch(ref);
  }
}

String _$entrySearchHash() => r'72b59e93eb4651b7c09f48999e641133fe064653';

@ProviderFor(libraryFindMatches)
final libraryFindMatchesProvider = LibraryFindMatchesProvider._();

final class LibraryFindMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>?>,
          Set<String>?,
          FutureOr<Set<String>?>
        >
    with $FutureModifier<Set<String>?>, $FutureProvider<Set<String>?> {
  LibraryFindMatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryFindMatchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryFindMatchesHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>?> create(Ref ref) {
    return libraryFindMatches(ref);
  }
}

String _$libraryFindMatchesHash() =>
    r'843894374a5adf2133c8da7e3f075c101a742062';

@ProviderFor(LibraryHoveredRow)
final libraryHoveredRowProvider = LibraryHoveredRowProvider._();

final class LibraryHoveredRowProvider
    extends $NotifierProvider<LibraryHoveredRow, String?> {
  LibraryHoveredRowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryHoveredRowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryHoveredRowHash();

  @$internal
  @override
  LibraryHoveredRow create() => LibraryHoveredRow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$libraryHoveredRowHash() => r'3bccbdf9203266a31861dd16b2bb305ade60a011';

abstract class _$LibraryHoveredRow extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LibraryLetterJump)
final libraryLetterJumpProvider = LibraryLetterJumpProvider._();

final class LibraryLetterJumpProvider
    extends
        $NotifierProvider<LibraryLetterJump, ({int count, String letter})?> {
  LibraryLetterJumpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryLetterJumpProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryLetterJumpHash();

  @$internal
  @override
  LibraryLetterJump create() => LibraryLetterJump();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int count, String letter})? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int count, String letter})?>(
        value,
      ),
    );
  }
}

String _$libraryLetterJumpHash() => r'cad6df7729f4438ee156e4bfca02f354d6e9142c';

abstract class _$LibraryLetterJump
    extends $Notifier<({int count, String letter})?> {
  ({int count, String letter})? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({int count, String letter})?,
              ({int count, String letter})?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({int count, String letter})?,
                ({int count, String letter})?
              >,
              ({int count, String letter})?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LibrarySortChoice)
final librarySortChoiceProvider = LibrarySortChoiceProvider._();

final class LibrarySortChoiceProvider
    extends $NotifierProvider<LibrarySortChoice, LibrarySort> {
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

@ProviderFor(LibraryLayoutChoice)
final libraryLayoutChoiceProvider = LibraryLayoutChoiceProvider._();

final class LibraryLayoutChoiceProvider
    extends $AsyncNotifierProvider<LibraryLayoutChoice, LibraryLayout> {
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
