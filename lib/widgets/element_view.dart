import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doc_element.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'shape_geometry.dart';

/// Renders a single [DocElement] on the page and handles selection, dragging,
/// resizing and (for text) inline editing. All geometry is in points; [scale]
/// converts points to on-screen pixels.
class ElementView extends StatelessWidget {
  const ElementView({
    super.key,
    required this.element,
    required this.scale,
    required this.pageWpt,
    required this.pageHpt,
  });

  final DocElement element;
  final double scale;
  final double pageWpt;
  final double pageHpt;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final selected =
        context.select<AppState, bool>((s) => s.selectedId == element.id);
    final editing =
        context.select<AppState, bool>((s) => s.editingId == element.id);

    final e = element;
    final w = e.w * scale;
    final h = e.h * scale;

    final content = Opacity(
      opacity: e.opacity,
      child: SizedBox(width: w, height: h, child: _content(editing, state)),
    );

    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => state.select(e.id),
      onDoubleTap: e.isText ? () => state.startEditing(e.id) : null,
      onPanStart: editing
          ? null
          : (_) {
              state.select(e.id);
              state.record();
            },
      onPanUpdate: editing
          ? null
          : (d) {
              var nx = (e.x + d.delta.dx / scale)
                  .clamp(-e.w + 20, pageWpt - 20)
                  .toDouble();
              var ny = (e.y + d.delta.dy / scale)
                  .clamp(-e.h + 20, pageHpt - 20)
                  .toDouble();
              // Snap to the page's horizontal / vertical centre for accuracy.
              if (((nx + e.w / 2) - pageWpt / 2).abs() < 6) {
                nx = (pageWpt - e.w) / 2;
              }
              if (((ny + e.h / 2) - pageHpt / 2).abs() < 6) {
                ny = (pageHpt - e.h) / 2;
              }
              e.x = nx;
              e.y = ny;
              state.touch();
            },
      child: content,
    );

    return Positioned(
      left: e.x * scale,
      top: e.y * scale,
      child: Transform.rotate(
        angle: e.rotation * math.pi / 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            body,
            if (selected && !editing) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.seed, width: 1.5),
                    ),
                  ),
                ),
              ),
              _handle(
                right: -7,
                bottom: -7,
                icon: Icons.open_in_full,
                onStart: state.record,
                onPan: (d) {
                  e.w = math.max(20, e.w + d.delta.dx / scale);
                  e.h = math.max(10, e.h + d.delta.dy / scale);
                  state.touch();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(bool editing, AppState state) {
    final e = element;
    switch (e.type) {
      case ElementType.text:
        if (editing) {
          return _InlineEditor(element: e, scale: scale);
        }
        return Container(
          color: e.fillColor,
          alignment: _alignFor(e.align),
          child: Text(
            e.text.isEmpty ? ' ' : e.text,
            textAlign: e.align,
            style: _textStyle(e, scale),
          ),
        );
      case ElementType.image:
        if (e.imageBytes == null) {
          return Container(color: Colors.grey.shade200);
        }
        return Image.memory(e.imageBytes!, fit: BoxFit.fill);
      case ElementType.rect:
        return Container(
          decoration: BoxDecoration(
            color: e.fillColor,
            border: e.strokeWidth > 0
                ? Border.all(color: e.stroke, width: e.strokeWidth * scale)
                : null,
          ),
        );
      case ElementType.ellipse:
        return Container(
          decoration: BoxDecoration(
            color: e.fillColor,
            borderRadius:
                BorderRadius.all(Radius.elliptical(e.w * scale, e.h * scale)),
            border: e.strokeWidth > 0
                ? Border.all(color: e.stroke, width: e.strokeWidth * scale)
                : null,
          ),
        );
      case ElementType.line:
        return Container(color: e.stroke);
      case ElementType.polygon:
        return CustomPaint(
          painter: _ShapePainter(
            points: shapePoints(e.shape),
            fill: e.fillColor,
            stroke: e.strokeWidth > 0 ? e.stroke : null,
            strokeWidth: e.strokeWidth * scale,
          ),
          child: const SizedBox.expand(),
        );
    }
  }

  Widget _handle({
    double? right,
    double? bottom,
    required IconData icon,
    required void Function(DragUpdateDetails) onPan,
    VoidCallback? onStart,
  }) {
    return Positioned(
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onPanStart: onStart == null ? null : (_) => onStart(),
        onPanUpdate: onPan,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.seed, width: 1.5),
            boxShadow: AppTheme.softShadow,
          ),
          child: Icon(icon, size: 10, color: AppTheme.seed),
        ),
      ),
    );
  }

  static Alignment _alignFor(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}

TextStyle _textStyle(DocElement e, double scale) {
  return TextStyle(
    fontFamily: e.fontFamily,
    fontSize: e.fontSize * scale,
    color: e.textColor,
    fontWeight: e.bold ? FontWeight.bold : FontWeight.normal,
    fontStyle: e.italic ? FontStyle.italic : FontStyle.normal,
    decoration: e.underline ? TextDecoration.underline : TextDecoration.none,
    letterSpacing: e.letterSpacing * scale,
    height: 1.2,
  );
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({
    required this.points,
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
  });

  final List<List<double>> points;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points[i][0] * size.width;
      final y = points[i][1] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    if (fill != null) {
      canvas.drawPath(path, Paint()..color = fill!);
    }
    if (stroke != null && strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.points != points;
}

class _InlineEditor extends StatefulWidget {
  const _InlineEditor({required this.element, required this.scale});
  final DocElement element;
  final double scale;

  @override
  State<_InlineEditor> createState() => _InlineEditorState();
}

class _InlineEditorState extends State<_InlineEditor> {
  late final TextEditingController _c =
      TextEditingController(text: widget.element.text);
  late final FocusNode _f = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _f.requestFocus();
      // Keep the edited box visible once the keyboard pushes the view up.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          Scrollable.ensureVisible(context,
              alignment: 0.3, duration: const Duration(milliseconds: 250));
        }
      });
    });
    _f.addListener(() {
      if (!_f.hasFocus && mounted) context.read<AppState>().stopEditing();
    });
  }

  @override
  void dispose() {
    widget.element.text = _c.text;
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.element;
    return Container(
      color: e.fillColor ?? Colors.white,
      child: TextField(
        controller: _c,
        focusNode: _f,
        maxLines: null,
        textAlign: e.align,
        style: _textStyle(e, widget.scale),
        cursorColor: AppTheme.seed,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onChanged: (v) => e.text = v,
      ),
    );
  }
}
