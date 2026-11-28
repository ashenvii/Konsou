import 'package:flutter/widgets.dart';

/// A fill that runs from the first of [colors] at the top to the last at the
/// bottom, at [stops] when given.
class DownFade extends StatelessWidget {
  const DownFade({super.key, required this.colors, this.stops});

  final List<Color> colors;
  final List<double>? stops;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ),
    ),
  );
}
