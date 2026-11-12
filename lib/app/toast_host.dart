import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../components/countdown.dart';
import '../library/earlier_titles.dart';

part 'toast_host.g.dart';

typedef ToastSink = void Function(ToastMessage message);

typedef Undo = Future<void> Function();

const toastMessageTime = Duration(seconds: 4);
const toastActionTime = Duration(seconds: 6);

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

@Riverpod(keepAlive: true)
class ToastHost extends _$ToastHost {
  late final Countdown time = Countdown(onDone: dismiss);

  @override
  ToastState build() {
    ref.onDispose(time.dispose);
    return const ToastState();
  }

  void show(ToastMessage message) {
    _missed();
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
    if (missed) _missed();
    time.cancel();
    state = const ToastState();
  }

  void setPointerOver(bool over) {
    if (state.shown == null || state.pointerOver == over) return;
    state = state.copyWith(pointerOver: over);
    _follow();
  }

  void setReviewOpen(bool open) {
    if (state.shown == null || state.reviewOpen == open) return;
    state = state.copyWith(reviewOpen: open);
    _follow();
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

  void _missed() {
    final shown = state.shown;
    if (shown?.review != null) shown!.onMissed?.call();
  }

  void _restart(ToastMessage message) {
    time.start(message.lifetime);
    _follow();
  }

  void _follow() {
    if (state.shown == null) return;
    state.held ? time.pause() : time.resume();
  }
}
