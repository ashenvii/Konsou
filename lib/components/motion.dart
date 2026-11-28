import 'package:flutter/widgets.dart';

/// [duration], or zero when the system asks for less motion.
Duration chooseMotionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
