import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../components/countdown.dart';
import '../library/earlier_titles.dart';

part 'toast_host.g.dart';

/// Shows a toast.
typedef ToastSink = void Function(ToastMessage message);

/// Reverses an edit.
typedef Undo = Future<void> Function();

/// How long a toast with no action stays.
const toastMessageTime = Duration(seconds: 4);
/// How long a toast with an action, such as Undo, stays.
const toastActionTime = Duration(seconds: 6);

/// The earlier titles offered for marking after an entry is finished.
class ReviewOffer {
  const ReviewOffer({
    required this.entryId,
    required this.titles,
    this.undoFinish,
  });

  final String entryId;
  final List<EarlierTitle> titles;

  final Undo? undoFinish;
}

/// One toast: its text and any undo, review or rating it carries.
class ToastMessage {
  ToastMessage(
    this.text, {
    this.undo,
    this.review,
    this.rateEntryId,
    this.rating,
    this.onMissed,
  });

  final String text;
  final Undo? undo;
  final ReviewOffer? review;
  final String? rateEntryId;

  final int? rating;
  final VoidCallback? onMissed;

  bool get hasAction => undo != null || review != null;
  Duration get lifetime => hasAction ? toastActionTime : toastMessageTime;
}

/// The toast shown now, and whether the pointer or the review holds it.
class ToastState {
  const ToastState({
    this.shown,
    this.rating,
    this.pointerOver = false,
    this.reviewOpen = false,
  });

  final ToastMessage? shown;

  final int? rating;
  final bool pointerOver;
  final bool reviewOpen;

  bool get held => pointerOver || reviewOpen;

  ToastState copyWith({
    int? rating,
    bool clearRating = false,
    bool? pointerOver,
    bool? reviewOpen,
  }) => ToastState(
    shown: shown,
    rating: clearRating ? null : (rating ?? this.rating),
    pointerOver: pointerOver ?? this.pointerOver,
    reviewOpen: reviewOpen ?? this.reviewOpen,
  );
}

/// Shows one toast at a time and runs its timer, undo, review and rating.
@Riverpod(keepAlive: true)
class ToastHost extends _$ToastHost {
  late final Countdown time = Countdown(onDone: dismiss);

  @override
  ToastState build() {
    ref.onDispose(time.dispose);
    return const ToastState();
  }

  void show(ToastMessage message) {
    _saveMissedReview();
    _replaceWith(message, message.rating);
  }

  void answerReview(ToastMessage message) =>
      _replaceWith(message, message.rating ?? state.rating);

  void _replaceWith(ToastMessage message, int? rating) {
    state = ToastState(
      shown: message,
      rating: rating,
      pointerOver: state.pointerOver,
    );
    _restart(message);
  }

  void dismiss({bool missed = true}) {
    if (missed) _saveMissedReview();
    time.cancel();
    state = const ToastState();
  }

  void setPointerOver(bool over) {
    if (state.shown == null || state.pointerOver == over) return;
    state = state.copyWith(pointerOver: over);
    _followHold();
  }

  void setReviewOpen(bool open) {
    if (state.shown == null || state.reviewOpen == open) return;
    state = state.copyWith(reviewOpen: open);
    _followHold();
  }

  void rate(int? score) {
    final shown = state.shown;
    if (shown == null) return;
    state = score == null
        ? state.copyWith(clearRating: true)
        : state.copyWith(rating: score);
    _restart(shown);
  }

  Future<bool> undoNewest() async {
    final undo = state.shown?.undo;
    if (undo == null) return false;
    dismiss(missed: false);
    await undo();
    return true;
  }

  void _saveMissedReview() {
    final shown = state.shown;
    if (shown?.review != null) shown!.onMissed?.call();
  }

  void _restart(ToastMessage message) {
    time.start(message.lifetime);
    _followHold();
  }

  void _followHold() {
    if (state.shown == null) return;
    state.held ? time.pause() : time.resume();
  }
}
