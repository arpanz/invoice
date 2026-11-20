import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_animations.dart';

/// The rendered pages of a document, laid out as sheets of paper.
///
/// Pinch or double-tap to zoom. While a new render is on its way the last
/// pages stay on screen, dimmed, so the view never blanks; the first render
/// shows an empty sheet in their place. New pages ease in.
class DocumentPagesView extends StatefulWidget {
  final List<MemoryImage>? pages;
  final bool loading;
  final String errorText;

  const DocumentPagesView({
    super.key,
    required this.pages,
    required this.loading,
    this.errorText = 'Could not show the preview. Please try again.',
  });

  @override
  State<DocumentPagesView> createState() => _DocumentPagesViewState();
}

class _DocumentPagesViewState extends State<DocumentPagesView> with SingleTickerProviderStateMixin {
  static const _zoom = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: AppAnimations.medium,
  );
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _zoomAnim.addListener(() {
      final tween = _zoomTween;
      if (tween != null) _transform.value = tween.value;
    });
  }

  @override
  void dispose() {
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.05;
    final target = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
          ..translateByDouble(-_doubleTapAt.dx * (_zoom - 1), -_doubleTapAt.dy * (_zoom - 1), 0, 1)
          ..scaleByDouble(_zoom, _zoom, 1, 1));
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _transform.value = target;
      return;
    }
    _zoomTween = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _zoomAnim, curve: AppAnimations.defaultCurve));
    _zoomAnim.forward(from: 0);
  }

  static const _sheetShadow = [
    BoxShadow(color: Color.fromRGBO(40, 30, 15, 0.10), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color.fromRGBO(40, 30, 15, 0.14), blurRadius: 28, offset: Offset(0, 12)),
  ];

  Widget _sheet({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: _sheetShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    if (pages == null || pages.isEmpty) {
      if (!widget.loading) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(widget.errorText, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          ),
        );
      }
      // An empty sheet where the first page will land.
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: _sheet(
          child: AspectRatio(
            aspectRatio: 210 / 297,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF9A8F7C)),
              ),
            ),
          ),
        ),
      );
    }

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
            onDoubleTap: _toggleZoom,
            child: InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: 1.0,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: constraints.maxWidth,
                child: AnimatedOpacity(
                  duration: AppAnimations.fast,
                  opacity: widget.loading ? 0.45 : 1,
                  child: TweenAnimationBuilder<double>(
                    // A new render is a new list, so it eases in again.
                    key: ObjectKey(pages),
                    tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                    duration: AppAnimations.slow,
                    curve: AppAnimations.defaultCurve,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                      child: Column(
                        children: [
                          for (final page in pages) _sheet(child: Image(image: page, fit: BoxFit.contain)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.loading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2, color: AppColors.ink, backgroundColor: Colors.transparent),
          ),
      ],
    );
  }
}
