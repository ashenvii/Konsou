import 'package:flutter/widgets.dart';

import 'picture_crop.dart';
import '../design/tokens.dart';
import 'motion.dart';

/// A picture that covers its box, cropped to its busiest band. It never
/// swaps in place: the first picture fades in, and each new one is decoded
/// first and then fades in over whatever shows, even halfway through a fade,
/// with the ones under it dropped once it is in. With no [look] it fades out.
class PictureFade extends StatefulWidget {
  const PictureFade({super.key, required this.look});

  final PictureLook? look;

  @override
  State<PictureFade> createState() => _PictureFadeState();
}

class _Layer {
  _Layer(this.look, this.image, this.controller, Curve curve)
    : opacity = CurvedAnimation(parent: controller, curve: curve);

  final PictureLook look;
  final ImageProvider image;
  final AnimationController controller;
  final Animation<double> opacity;

  void dispose() {
    (opacity as CurvedAnimation).dispose();
    controller.dispose();
  }
}

class _PictureFadeState extends State<PictureFade>
    with TickerProviderStateMixin {
  final _layers = <_Layer>[];
  String? _wanted;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // the first picture waits for the context, which decoding needs
    if (!_started) {
      _started = true;
      _arrive(widget.look);
    }
  }

  @override
  void didUpdateWidget(PictureFade old) {
    super.didUpdateWidget(old);
    if (widget.look?.file.path != old.look?.file.path) _arrive(widget.look);
  }

  Future<void> _arrive(PictureLook? look) async {
    _wanted = look?.file.path;
    if (look == null) return setState(() {});
    final image = FileImage(look.file);
    await precacheImage(image, context, onError: (_, _) {});
    if (!mounted || _wanted != look.file.path) return;
    final first = _layers.isEmpty;
    final controller = AnimationController(
      vsync: this,
      duration: chooseMotionDuration(
        context,
        first ? Tokens.motionFirstFade : Tokens.motionPictureChange,
      ),
    );
    final layer = _Layer(
      look,
      image,
      controller,
      first ? Curves.easeOut : Curves.easeInOut,
    );
    setState(() => _layers.add(layer));
    await controller.forward().orCancel.catchError((_) {});
    if (!mounted || !_layers.contains(layer)) return;
    // everything under it is hidden now
    final under = _layers.sublist(0, _layers.indexOf(layer));
    setState(() => _layers.removeWhere(under.contains));
    for (final gone in under) {
      gone.dispose();
    }
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      layer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _wanted == null ? 0 : 1,
      duration: chooseMotionDuration(context, Tokens.motionFirstFade),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            for (final layer in _layers)
              FadeTransition(
                opacity: layer.opacity,
                child: Image(
                  image: layer.image,
                  fit: BoxFit.cover,
                  alignment: cropAlignment(
                    layer.look.rows,
                    Size(
                      layer.look.width.toDouble(),
                      layer.look.height.toDouble(),
                    ),
                    constraints.biggest,
                  ),
                  gaplessPlayback: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
