// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toast_host.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ToastHost)
final toastHostProvider = ToastHostProvider._();

final class ToastHostProvider extends $NotifierProvider<ToastHost, ToastState> {
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

String _$toastHostHash() => r'537cb6de8a3ca3cd43f7d41564e611ab5b50b017';

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
