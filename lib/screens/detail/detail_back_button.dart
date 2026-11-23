import 'package:flutter/widgets.dart';

import '../../components/solid_icon_button.dart';
import '../../icons/app_icons.dart';
import 'jump_bar.dart';

/// The back button, a white key with a dark arrow. It floats over the top of
/// the Detail page and moves into the [JumpBar] at the top, the same either
/// place.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SolidIconButton(
    icon: AppIcons.arrowLeft,
    label: 'Back',
    onPressed: onBack,
  );
}
