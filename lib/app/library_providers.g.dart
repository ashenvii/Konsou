// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Library's rows, reloaded at most once per gap after data changes.

@ProviderFor(libraryRows)
final libraryRowsProvider = LibraryRowsProvider._();

/// The Library's rows, reloaded at most once per gap after data changes.

final class LibraryRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryRow>>,
          List<LibraryRow>,
          FutureOr<List<LibraryRow>>
        >
    with $FutureModifier<List<LibraryRow>>, $FutureProvider<List<LibraryRow>> {
  /// The Library's rows, reloaded at most once per gap after data changes.
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

/// The shared [EntryEdits], telling sync about each change.

@ProviderFor(entryEdits)
final entryEditsProvider = EntryEditsProvider._();

/// The shared [EntryEdits], telling sync about each change.

final class EntryEditsProvider
    extends $FunctionalProvider<EntryEdits, EntryEdits, EntryEdits>
    with $Provider<EntryEdits> {
  /// The shared [EntryEdits], telling sync about each change.
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

/// The shared [EntryActions], wired to the toast host.

@ProviderFor(entryActions)
final entryActionsProvider = EntryActionsProvider._();

/// The shared [EntryActions], wired to the toast host.

final class EntryActionsProvider
    extends $FunctionalProvider<EntryActions, EntryActions, EntryActions>
    with $Provider<EntryActions> {
  /// The shared [EntryActions], wired to the toast host.
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

/// The status tab the Library shows.

@ProviderFor(LibraryTabChoice)
final libraryTabChoiceProvider = LibraryTabChoiceProvider._();

/// The status tab the Library shows.
final class LibraryTabChoiceProvider
    extends $NotifierProvider<LibraryTabChoice, LibraryTab> {
  /// The status tab the Library shows.
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

/// The status tab the Library shows.

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

/// Rows an edit moved out of the tab, kept in view until the tab changes.

@ProviderFor(LibraryKept)
final libraryKeptProvider = LibraryKeptProvider._();

/// Rows an edit moved out of the tab, kept in view until the tab changes.
final class LibraryKeptProvider
    extends $NotifierProvider<LibraryKept, Set<String>> {
  /// Rows an edit moved out of the tab, kept in view until the tab changes.
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

/// Rows an edit moved out of the tab, kept in view until the tab changes.

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

/// The Find field's text, or null while Find is closed.

@ProviderFor(LibraryFindChoice)
final libraryFindChoiceProvider = LibraryFindChoiceProvider._();

/// The Find field's text, or null while Find is closed.
final class LibraryFindChoiceProvider
    extends $NotifierProvider<LibraryFindChoice, String?> {
  /// The Find field's text, or null while Find is closed.
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

/// The Find field's text, or null while Find is closed.

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

/// The title index over the user's entries, rebuilt when the rows change.

@ProviderFor(entrySearch)
final entrySearchProvider = EntrySearchProvider._();

/// The title index over the user's entries, rebuilt when the rows change.

final class EntrySearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<EntrySearch>,
          EntrySearch,
          FutureOr<EntrySearch>
        >
    with $FutureModifier<EntrySearch>, $FutureProvider<EntrySearch> {
  /// The title index over the user's entries, rebuilt when the rows change.
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

/// The entry ids Find matches, or null when Find is empty.

@ProviderFor(libraryFindMatches)
final libraryFindMatchesProvider = LibraryFindMatchesProvider._();

/// The entry ids Find matches, or null when Find is empty.

final class LibraryFindMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>?>,
          Set<String>?,
          FutureOr<Set<String>?>
        >
    with $FutureModifier<Set<String>?>, $FutureProvider<Set<String>?> {
  /// The entry ids Find matches, or null when Find is empty.
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

/// The entry the pointer is over, for the keys that act on a row.

@ProviderFor(LibraryHoveredRow)
final libraryHoveredRowProvider = LibraryHoveredRowProvider._();

/// The entry the pointer is over, for the keys that act on a row.
final class LibraryHoveredRowProvider
    extends $NotifierProvider<LibraryHoveredRow, String?> {
  /// The entry the pointer is over, for the keys that act on a row.
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

/// The entry the pointer is over, for the keys that act on a row.

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

/// The letter the A to Z strip last jumped to; the count makes a repeat fire.

@ProviderFor(LibraryLetterJump)
final libraryLetterJumpProvider = LibraryLetterJumpProvider._();

/// The letter the A to Z strip last jumped to; the count makes a repeat fire.
final class LibraryLetterJumpProvider
    extends
        $NotifierProvider<LibraryLetterJump, ({int count, String letter})?> {
  /// The letter the A to Z strip last jumped to; the count makes a repeat fire.
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

/// The letter the A to Z strip last jumped to; the count makes a repeat fire.

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

/// The Library's sort from the menu, saved between runs.

@ProviderFor(LibrarySortChoice)
final librarySortChoiceProvider = LibrarySortChoiceProvider._();

/// The Library's sort from the menu, saved between runs.
final class LibrarySortChoiceProvider
    extends $AsyncNotifierProvider<LibrarySortChoice, LibrarySort> {
  /// The Library's sort from the menu, saved between runs.
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
}

String _$librarySortChoiceHash() => r'dc95aaf7ce05cdf634529799848300a9101db2fb';

/// The Library's sort from the menu, saved between runs.

abstract class _$LibrarySortChoice extends $AsyncNotifier<LibrarySort> {
  FutureOr<LibrarySort> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LibrarySort>, LibrarySort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LibrarySort>, LibrarySort>,
              AsyncValue<LibrarySort>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// How many quick panels are open. While one is, the Library keeps its rows
/// in the order they had, so an edit made in the panel does not move the row
/// out from under it.

@ProviderFor(LibraryPanelOpen)
final libraryPanelOpenProvider = LibraryPanelOpenProvider._();

/// How many quick panels are open. While one is, the Library keeps its rows
/// in the order they had, so an edit made in the panel does not move the row
/// out from under it.
final class LibraryPanelOpenProvider
    extends $NotifierProvider<LibraryPanelOpen, int> {
  /// How many quick panels are open. While one is, the Library keeps its rows
  /// in the order they had, so an edit made in the panel does not move the row
  /// out from under it.
  LibraryPanelOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryPanelOpenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryPanelOpenHash();

  @$internal
  @override
  LibraryPanelOpen create() => LibraryPanelOpen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$libraryPanelOpenHash() => r'dc9b6060ec5db7ad43b24070035564be660e8695';

/// How many quick panels are open. While one is, the Library keeps its rows
/// in the order they had, so an edit made in the panel does not move the row
/// out from under it.

abstract class _$LibraryPanelOpen extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The list header bar's sort, over the menu's while set. Not saved: a new
/// start shows the menu's sort.

@ProviderFor(LibraryColumnSortChoice)
final libraryColumnSortChoiceProvider = LibraryColumnSortChoiceProvider._();

/// The list header bar's sort, over the menu's while set. Not saved: a new
/// start shows the menu's sort.
final class LibraryColumnSortChoiceProvider
    extends $NotifierProvider<LibraryColumnSortChoice, ColumnSort?> {
  /// The list header bar's sort, over the menu's while set. Not saved: a new
  /// start shows the menu's sort.
  LibraryColumnSortChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryColumnSortChoiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryColumnSortChoiceHash();

  @$internal
  @override
  LibraryColumnSortChoice create() => LibraryColumnSortChoice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColumnSort? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColumnSort?>(value),
    );
  }
}

String _$libraryColumnSortChoiceHash() =>
    r'efd26241c73a90bd1c7470504a0a3959b02fa840';

/// The list header bar's sort, over the menu's while set. Not saved: a new
/// start shows the menu's sort.

abstract class _$LibraryColumnSortChoice extends $Notifier<ColumnSort?> {
  ColumnSort? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ColumnSort?, ColumnSort?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ColumnSort?, ColumnSort?>,
              ColumnSort?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Grid or list, saved between runs.

@ProviderFor(LibraryLayoutChoice)
final libraryLayoutChoiceProvider = LibraryLayoutChoiceProvider._();

/// Grid or list, saved between runs.
final class LibraryLayoutChoiceProvider
    extends $AsyncNotifierProvider<LibraryLayoutChoice, LibraryLayout> {
  /// Grid or list, saved between runs.
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
    r'091ca932d2592b1d6ba01f37f58e59977ff1a083';

/// Grid or list, saved between runs.

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
