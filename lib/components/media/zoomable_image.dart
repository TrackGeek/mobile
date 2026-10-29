import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ZoomableImage extends StatefulWidget {
  const ZoomableImage({
    super.key,
    required this.url,
    required this.label,
    this.onInteractionChanged,
    this.image,
  });

  final String url;
  final String label;
  final ValueChanged<bool>? onInteractionChanged;
  final ImageProvider? image;

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  final _transform = TransformationController();
  final _pointers = <int>{};
  Offset _doubleTapPosition = Offset.zero;
  bool _engaged = false;
  bool _wasZoomed = false;

  bool get _zoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final engaged = _zoomed || _pointers.length > 1;
    if (engaged == _engaged && _zoomed == _wasZoomed) return;
    final changed = engaged != _engaged;
    setState(() {
      _engaged = engaged;
      _wasZoomed = _zoomed;
    });
    if (changed) widget.onInteractionChanged?.call(engaged);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_zoomed) {
      _transform.value = Matrix4.identity();
    } else {
      _transform.value = Matrix4.identity()
        ..translateByDouble(
          -_doubleTapPosition.dx * 2,
          -_doubleTapPosition.dy * 2,
          0,
          1,
        )
        ..scaleByDouble(3, 3, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      image: true,
      onIncrease: () {
        final size = context.size;
        _doubleTapPosition = size == null
            ? Offset.zero
            : Offset(size.width / 2, size.height / 2);
        if (!_zoomed) _toggleZoom();
      },
      onDecrease: () => _transform.value = Matrix4.identity(),
      child: Listener(
        onPointerDown: (event) {
          _pointers.add(event.pointer);
          _onTransform();
        },
        onPointerUp: (event) {
          _pointers.remove(event.pointer);
          _onTransform();
        },
        onPointerCancel: (event) {
          _pointers.remove(event.pointer);
          _onTransform();
        },
        child: GestureDetector(
          onDoubleTapDown: (details) =>
              _doubleTapPosition = details.localPosition,
          onDoubleTap: _toggleZoom,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 8,
            panEnabled: _zoomed,
            child: SizedBox.expand(
              child: widget.url.isEmpty && widget.image == null
                  ? const Center(child: _ImagePlaceholder())
                  : Image(
                      image: widget.image ?? NetworkImage(widget.url),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes == null
                                    ? null
                                    : progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!,
                              ),
                            ),
                      errorBuilder: (_, _, _) =>
                          const Center(child: _ImagePlaceholder()),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const HugeIcon(
      icon: HugeIcons.strokeRoundedImage01,
      size: 48,
      color: Colors.white54,
    );
  }
}
