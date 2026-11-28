import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/close_on_escape.dart';
import '../components/page_dim.dart';
import 'cover_view.dart';
import '../components/earlier_review.dart';
import '../components/presence.dart';
import '../components/star_rating.dart';
import '../components/text_action.dart';
import '../components/toast_timer.dart';
import '../components/toast_view.dart';
import '../design/tokens.dart';
import '../library/row_labels.dart';
import 'library_providers.dart';
import 'toast_host.dart';
import 'toast_words.dart';

const _reviewWords = EarlierReviewWords(
  heading: reviewHeading,
  extrasHeading: extrasHeading,
  notNow: notNowLabel,
  mark: markButton,
  storiesHeading: storiesHeading,
  all: selectAllLabel,
  none: selectNoneLabel,
  selected: selectedCount,
  mediaType: formatType,
  episodes: formatEpisodes,
  status: earlierStatusLabel,
  setTo: reviewSetTo,
);

/// Draws the toast host's toast over the page, clear of the rail.
class ToastLayer extends ConsumerWidget {
  const ToastLayer({super.key, this.leftInset = 0});

  final double leftInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toastHostProvider);
    final shown = state.shown;
    final host = ref.read(toastHostProvider.notifier);
    final review = shown?.review;
    final reviewOpen = review != null && state.reviewOpen;
    return Stack(
      children: [
        if (reviewOpen)
          Positioned.fill(
            child: PageDim(onClose: () => host.setReviewOpen(false)),
          ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              leftInset + Tokens.space4,
              Tokens.space4,
              Tokens.space4,
              Tokens.space4,
            ),
            // a toast fades out too, so it stays built while it leaves
            child: Presence(
              visible: shown != null,
              child: shown == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: MouseRegion(
                        onEnter: (_) => host.setPointerOver(true),
                        onExit: (_) => host.setPointerOver(false),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: Tokens.toastMaxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: reviewOpen
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.center,
                            children: [
                              if (reviewOpen) ...[
                                Flexible(
                                  child: CloseOnEscape(
                                    onClose: () => host.setReviewOpen(false),
                                    child: FocusScope(
                                      autofocus: true,
                                      child: EarlierReview(
                                        titles: review.titles,
                                        words: _reviewWords,
                                        cover: (title, width) => CoverView(
                                          malId: title.malId,
                                          width: width,
                                        ),
                                        onMark: (chosen, status) => ref
                                            .read(entryActionsProvider)
                                            .acceptReview(
                                              review,
                                              chosen,
                                              status: status,
                                            ),
                                        onNotNow: () => ref
                                            .read(entryActionsProvider)
                                            .notNow(review),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Tokens.space2),
                              ],
                              _buildToast(ref, state, shown, host),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToast(
    WidgetRef ref,
    ToastState state,
    ToastMessage shown,
    ToastHost host,
  ) {
    final rateEntryId = shown.rateEntryId;
    return ToastView(
      // a toast with stars keeps one width, so it never changes size
      wide: rateEntryId != null,
      message: shown.text,
      closeLabel: closeToastLabel,
      onClose: host.dismiss,
      actions: [
        if (shown.review != null)
          TextAction(
            label: reviewLabel,
            quiet: true,
            onPressed: () => host.setReviewOpen(true),
          ),
        if (shown.undo != null)
          TextAction(label: undoLabel, onPressed: host.undoNewest),
      ],
      footer: rateEntryId == null
          ? null
          : StarRating(
              spread: true,
              value: state.rating,
              labelFor: rateStarLabel,
              clearLabel: clearRatingLabel,
              onChanged: (score) {
                host.rate(score);
                ref.read(entryActionsProvider).rate(rateEntryId, score);
              },
            ),
      timer: ToastTimer(countdown: host.time),
    );
  }
}
