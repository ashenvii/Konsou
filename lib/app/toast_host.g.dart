// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toast_host.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shows one toast at a time and runs its timer, undo, review and rating.

@ProviderFor(ToastHost)
final toastHostProvider = ToastHostProvider._();

/// Shows one toast at a time and runs its timer, undo, review and rating.
final class ToastHostProvider extends $NotifierProvider<ToastHost, ToastState> {
  /// Shows one toast at a time and runs its timer, undo, review and rating.
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

String _$toastHostHash() => r'eb2c41d8cb6854faee08abdb9c46b91c7bf69d2e';

/// Shows one toast at a time and runs its timer, undo, review and rating.

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
