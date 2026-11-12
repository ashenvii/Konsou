import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/app_button.dart';
import '../components/app_popover.dart';
import '../components/earlier_review.dart';
import '../components/star_rating.dart';
import '../components/toast_view.dart';
import '../design/tokens.dart';
import 'library_providers.dart';
import 'toast_host.dart';
import 'toast_words.dart';

const _reviewWords = EarlierReviewWords(
  extrasHeading: extrasHeading,
  notNow: notNowLabel,
  mark: markButton,
);

/// Draws the app's toast over [child], at the bottom centre of the area it
/// fills, [Tokens.space4] up. [child] is the page area, so the toast never
/// covers the rail. The toast is announced to screen readers and never takes
/// focus.
class ToastLayer extends ConsumerWidget {
  const ToastLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toastHostProvider);
    final shown = state.shown;
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (shown != null)
          Positioned(
            left: Tokens.space4,
            right: Tokens.space4,
            bottom: Tokens.space4,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MouseRegion(
                onEnter: (_) =>
                    ref.read(toastHostProvider.notifier).setPointerOver(true),
                onExit: (_) =>
                    ref.read(toastHostProvider.notifier).setPointerOver(false),
                child: _Toast(shown: shown, rating: state.rating),
              ),
            ),
          ),
      ],
    );
  }
}

class _Toast extends ConsumerWidget {
  const _Toast({required this.shown, required this.rating});

  final ToastMessage shown;
  final int? rating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = shown.review;
    // the review popover opens above the whole toast, so it anchors to it
    if (review == null) return _view(ref, null);
    return AppPopover(
      key: ObjectKey(shown),
      gap: Tokens.space2,
      builder: (context, handle) => _view(ref, handle),
      popoverBuilder: (context, handle) => _HoldsToast(
        child: EarlierReview(
          titles: review.titles,
          words: _reviewWords,
          onMark: (chosen) {
            handle.close();
            ref.read(entryActionsProvider).acceptReview(chosen);
          },
          onNotNow: () {
            handle.close();
            ref.read(entryActionsProvider).notNow(review);
          },
        ),
      ),
    );
  }

  Widget _view(WidgetRef ref, PopoverHandle? reviewPopover) {
    final host = ref.read(toastHostProvider.notifier);
    final review = shown.review;
    return ToastView(
      message: rating != null ? rated(rating!) : shown.text,
      closeLabel: closeToastLabel,
      onClose: host.dismiss,
      actionLabel: shown.undo == null ? null : undoLabel,
      onAction: shown.undo == null ? null : host.undoNewest,
      footer: review == null
          ? null
          : Row(
              children: [
                StarRating(
                  value: rating,
                  labelFor: rateStarLabel,
                  hint: rateHint,
                  clearLabel: clearRatingLabel,
                  onChanged: (score) {
                    host.rate(score);
                    ref.read(entryActionsProvider).rate(review.entryId, score);
                  },
                ),
                const Spacer(),
                AppButton(label: reviewLabel, onPressed: reviewPopover?.open),
              ],
            ),
    );
  }
}

/// Tells the host review is open for as long as it is on screen.
class _HoldsToast extends ConsumerStatefulWidget {
  const _HoldsToast({required this.child});

  final Widget child;

  @override
  ConsumerState<_HoldsToast> createState() => _HoldsToastState();
}

class _HoldsToastState extends ConsumerState<_HoldsToast> {
  late final ToastHost _host = ref.read(toastHostProvider.notifier);

  @override
  void initState() {
    super.initState();
    // after the build, since this changes a provider
    Future.microtask(() => _host.setReviewOpen(true));
  }

  @override
  void dispose() {
    Future.microtask(() => _host.setReviewOpen(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
