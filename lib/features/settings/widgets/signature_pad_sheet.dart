import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';

// The pad is always white paper, in both themes, so its guide marks use
// fixed paper colours rather than theme tokens that flip in dark mode.
const _padHint = Color(0xFF6B6253);
const _padLine = Color(0xFFE3DACA);
const _padFaint = Color(0xFF9A8F7C);

class SignaturePadSheet extends StatefulWidget {
  const SignaturePadSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      // Strokes must not drag the sheet down or dismiss it.
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const SignaturePadSheet(),
    );
  }

  @override
  State<SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<SignaturePadSheet> {
  final List<List<Offset>> _strokes = [];

  /// Shown under the pad. A snackbar would sit behind this sheet.
  String? _notice;
  Color _penColor = const Color(0xFF0F172A); // Dark slate ink
  final double _penWidth = 3.0;
  bool _isSaving = false;

  final GlobalKey _canvasKey = GlobalKey();

  final List<Color> _availableColors = const [
    Color(0xFF0F172A), // Dark Navy/Black
    Color(0xFF1E40AF), // Classic Blue Ink
    Color(0xFF047857), // Forest Green
    Color(0xFF7C2D12), // Mahogany / Dark Red
  ];

  void _onPanStart(DragStartDetails details) {
    if (_notice != null) setState(() => _notice = null);
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _strokes.add([localPosition]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _strokes.isEmpty) return;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Bound check to keep signature within canvas area
    final size = renderBox.size;
    if (localPosition.dx >= 0 &&
        localPosition.dx <= size.width &&
        localPosition.dy >= 0 &&
        localPosition.dy <= size.height) {
      setState(() {
        _strokes.last.add(localPosition);
      });
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clear() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _strokes.clear();
      });
    }
  }

  Future<void> _saveSignature() async {
    if (_strokes.isEmpty) {
      setState(() => _notice = 'Draw your signature above, then save.');
      return;
    }

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      // Export only the drawn area (plus a small margin), at 2x for print,
      // so the signature fills its box on the PDF instead of printing small
      // inside a mostly blank canvas.
      final points = _strokes.expand((stroke) => stroke);
      var bounds = Rect.fromPoints(points.first, points.first);
      for (final p in points) {
        bounds = bounds.expandToInclude(Rect.fromPoints(p, p));
      }
      // A dot or a tiny scribble would be blown up to fill the signature
      // box on the PDF.
      if (bounds.longestSide < 24) {
        setState(() {
          _isSaving = false;
          _notice = 'That looks too small. Sign across the pad, then save.';
        });
        return;
      }
      bounds = bounds
          .inflate(_penWidth + 6)
          .intersect(Offset.zero & size);
      const pixelRatio = 2.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio);
      canvas.translate(-bounds.left, -bounds.top);

      final painter = _SignaturePainter(
        strokes: _strokes,
        color: _penColor,
        strokeWidth: _penWidth,
      );
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        (bounds.width * pixelRatio).ceil().clamp(1, 4096),
        (bounds.height * pixelRatio).ceil().clamp(1, 4096),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode signature image');
      }

      final buffer = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      if (mounted) {
        Navigator.pop(context, filePath);
      }
    } catch (e) {
      debugPrint('Settings action failed: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _notice = 'Could not save the signature. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.squirclePurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppIcons.draw,
                  color: AppColors.squirclePurpleIcon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Draw Signature',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Sign with your finger or stylus',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  AppIcons.close,
                  color: AppColors.slate500,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Drawing Area Canvas
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8), // warm paper white, fixed in both themes
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Baseline guide & instructions
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_strokes.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.edit,
                                  size: 16,
                                  color: _padHint,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Draw inside this box',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _padHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            height: 1,
                            color: _padLine,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Authorized Signatory',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _padHint,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'X',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _padFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Touch area & custom paint
                  GestureDetector(
                    key: _canvasKey,
                    behavior: HitTestBehavior.opaque,
                    // Start the stroke where the finger lands, not after the
                    // drag slop, so the first part of a stroke isn't lost.
                    dragStartBehavior: DragStartBehavior.down,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        color: _penColor,
                        strokeWidth: _penWidth,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 8),
            Text(
              _notice!,
              style: TextStyle(fontSize: 12.5, color: AppColors.accentRed),
            ),
          ],
          const SizedBox(height: 14),

          // Tools Toolbar (Color, Undo, Clear)
          Row(
            children: [
              // Pen Colors
              ...List.generate(_availableColors.length, (index) {
                final color = _availableColors[index];
                final isSelected = _penColor == color;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _penColor = color);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.canvas,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Undo Button
              IconButton(
                tooltip: 'Undo stroke',
                icon: const Icon(AppIcons.undo, size: 20),
                color: _strokes.isNotEmpty
                    ? AppColors.slate700
                    : AppColors.slate300,
                onPressed: _strokes.isNotEmpty ? _undo : null,
              ),

              // Clear Button
              IconButton(
                tooltip: 'Clear canvas',
                icon: const Icon(AppIcons.delete, size: 20),
                color: _strokes.isNotEmpty
                    ? AppColors.accentRed
                    : AppColors.slate300,
                onPressed: _strokes.isNotEmpty ? _clear : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slate700,
                    side: BorderSide(color: AppColors.slate200),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.check, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Use Signature',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          strokeWidth / 2,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 1; i < stroke.length; i++) {
        final p0 = stroke[i - 1];
        final p1 = stroke[i];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
