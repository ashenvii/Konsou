import 'package:flutter/widgets.dart';

Duration chooseMotionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
