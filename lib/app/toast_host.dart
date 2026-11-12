import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../library/earlier_titles.dart';

part 'toast_host.g.dart';

/// How long a message stays, and one that offers an action.
const toastMessageTime = Duration(seconds: 5);
const toastActionTime = Duration(seconds: 8);

/// The review a toast offers after a title is finished: [titles] are the
/// earlier ones not marked, [entryId] is the title just finished.
class ReviewOffer {
  const ReviewOffer({required this.entryId, required this.titles});

  final String entryId;
  final List<EarlierTitle> titles;
}

/// One toast. [undo] gives it an Undo action; [review] makes it the review
/// toast, with the stars and the Review button.
class ToastMessage {
  ToastMessage(this.text, {this.undo, this.review});

  final String text;
  final Future<void> Function()? undo;
  final ReviewOffer? review;

  bool get hasAction => undo != null || review != null;
  Duration get lifetime => hasAction ? toastActionTime : toastMessageTime;
}

class ToastState {
  const ToastState({
    this.shown,
    this.rating,
    this.pointerOver = false,
    this.reviewOpen = false,
  });

  final ToastMessage? shown;

  /// The score given from the review toast, once it has been given.
  final int? rating;
  final bool pointerOver;
  final bool reviewOpen;

  bool get held => pointerOver || reviewOpen;
}

/// The app's one toast at a time. A new toast replaces the one showing,
/// except the review toast: others wait behind it, and only the newest
/// waits. The timer runs only while neither the pointer is on the toast nor
/// review is open; once both let go it starts over.
@Riverpod(keepAlive: true)
class ToastHost extends _$ToastHost {
  Timer? _timer;
  ToastMessage? _waiting;

  @override
  ToastState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ToastState();
  }

  void show(ToastMessage message) {
    if (state.shown?.review != null) {
      _waiting = message;
      return;
    }
    _open(message);
  }

  void _open(ToastMessage message) {
    state = ToastState(shown: message);
    _restartTimer();
  }

  void dismiss() {
    _timer?.cancel();
    final next = _waiting;
    _waiting = null;
    if (next != null) {
      _open(next);
    } else {
      state = const ToastState();
    }
  }

  void setPointerOver(bool over) {
    if (state.shown == null || state.pointerOver == over) return;
    state = ToastState(
      shown: state.shown,
      rating: state.rating,
      pointerOver: over,
      reviewOpen: state.reviewOpen,
    );
    _restartTimer();
  }

  void setReviewOpen(bool open) {
    if (state.shown == null || state.reviewOpen == open) return;
    state = ToastState(
      shown: state.shown,
      rating: state.rating,
      pointerOver: state.pointerOver,
      reviewOpen: open,
    );
    _restartTimer();
  }

  /// A rating from the review toast. It does not close the toast or touch
  /// its timer.
  void rate(int score) {
    if (state.shown == null) return;
    state = ToastState(
      shown: state.shown,
      rating: score,
      pointerOver: state.pointerOver,
      reviewOpen: state.reviewOpen,
    );
  }

  /// Runs the Undo of the toast showing, if it has one, and closes it.
  Future<bool> undoNewest() async {
    final undo = state.shown?.undo;
    if (undo == null) return false;
    dismiss();
    await undo();
    return true;
  }

  void _restartTimer() {
    _timer?.cancel();
    final shown = state.shown;
    if (shown == null || state.held) return;
    _timer = Timer(shown.lifetime, dismiss);
  }
}
