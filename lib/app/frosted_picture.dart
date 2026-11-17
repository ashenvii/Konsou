import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A picture drawn blurred, for the band behind the Detail page. The blur is
/// done once into a bitmap, so what is on screen is one plain image. A live
/// blur filter over a scrolling page left seams in it, and cost more to draw.
class FrostedPicture extends StatefulWidget {
  const FrostedPicture({
    super.key,
    required this.file,
    required this.width,
    required this.height,
    this.alignment = Alignment.center,
  });

  final File file;
  final double width;
  final double height;
  final Alignment alignment;

  // The blur is baked on a small copy, since it throws the detail away anyway;
  // the blur is the same share of the picture however wide it is drawn.
  static const _decodeWidth = 320;
  static const _sigma = 5.0;

  // the bake itself is kept, so a second ask while it runs waits on the first
  static final _baked = <String, Future<ui.Image?>>{};
  static const _keep = 6;

  @override
  State<FrostedPicture> createState() => _FrostedPictureState();

  static Future<ui.Image?> _bake(File file) {
    final path = file.path;
    final cached = _baked[path];
    if (cached != null) return cached;
    late final Future<ui.Image?> baking;
    baking = _bakeNow(file).then((image) {
      // a failed bake is tried again next time
      if (image == null && identical(_baked[path], baking)) {
        _baked.remove(path);
      }
      return image;
    });
    _baked[path] = baking;
    // an evicted picture is not disposed: a page may still be showing it, and
    // it is freed once nothing holds it
    if (_baked.length > _keep) _baked.remove(_baked.keys.first);
    return baking;
  }

  static Future<ui.Image?> _bakeNow(File file) async {
    try {
      final codec = await ui.instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: _decodeWidth,
      );
      final source = (await codec.getNextFrame()).image;
      codec.dispose();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.saveLayer(
        null,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: _sigma,
            sigmaY: _sigma,
            tileMode: TileMode.mirror,
          ),
      );
      canvas.drawImage(source, Offset.zero, Paint());
      canvas.restore();
      final picture = recorder.endRecording();
      final baked = await picture.toImage(source.width, source.height);
      picture.dispose();
      source.dispose();
      return baked;
    } catch (_) {
      return null;
    }
  }
}

class _FrostedPictureState extends State<FrostedPicture> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FrostedPicture old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) _load();
  }

  Future<void> _load() async {
    final path = widget.file.path;
    final image = await FrostedPicture._bake(widget.file);
    if (!mounted || widget.file.path != path || image == null) return;
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: image == null
          ? null
          : RawImage(
              image: image,
              fit: BoxFit.cover,
              alignment: widget.alignment,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}
