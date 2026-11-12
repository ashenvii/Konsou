// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toast_host.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's one toast at a time. A new toast replaces the one showing,
/// except the review toast: others wait behind it, and only the newest
/// waits. The timer runs only while neither the pointer is on the toast nor
/// review is open; once both let go it starts over.

@ProviderFor(ToastHost)
final toastHostProvider = ToastHostProvider._();

/// The app's one toast at a time. A new toast replaces the one showing,
/// except the review toast: others wait behind it, and only the newest
/// waits. The timer runs only while neither the pointer is on the toast nor
/// review is open; once both let go it starts over.
final class ToastHostProvider extends $NotifierProvider<ToastHost, ToastState> {
  /// The app's one toast at a time. A new toast replaces the one showing,
  /// except the review toast: others wait behind it, and only the newest
  /// waits. The timer runs only while neither the pointer is on the toast nor
  /// review is open; once both let go it starts over.
  ToastHostProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toastHostProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toastHostHash();

  @$internal
  @override
  ToastHost create() => ToastHost();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToastState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToastState>(value),
    );
  }
}

String _$toastHostHash() => r'd9e09302bca7f721dc8ff7c5ec4451c4129ca81f';

/// The app's one toast at a time. A new toast replaces the one showing,
/// except the review toast: others wait behind it, and only the newest
/// waits. The timer runs only while neither the pointer is on the toast nor
/// review is open; once both let go it starts over.

abstract class _$ToastHost extends $Notifier<ToastState> {
  ToastState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ToastState, ToastState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ToastState, ToastState>,
              ToastState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
