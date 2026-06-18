import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doc_element.dart';
import '../models/document.dart';
import '../models/page_size.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'element_view.dart';
import 'page_chrome.dart';

/// Draws one white page at the real aspect ratio with margins guide,
/// header/footer, freehand strokes and all elements.
class CanvasPage extends StatefulWidget {
  const CanvasPage({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.size,
    required this.displayWidth,
  });

  final DocPage page;
  final int pageIndex;
  final PaperSize size;
  final double displayWidth;

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  final List<Offset> _current = [];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scale = widget.displayWidth / widget.size.ptWidth;
    final height = widget.size.ptHeight * scale;
    final draw = state.drawMode;

    return Container(
      width: widget.displayWidth,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.pageShadows,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Margin guide.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: MarginPainter(state.doc, scale)),
            ),
          ),
          // Header (first page) and footer (all pages).
          if (widget.pageIndex == 0 && state.doc.header.enabled)
            HeaderBand(doc: state.doc, scale: scale),
          if (state.doc.footer.enabled)
            FooterBand(
              doc: state.doc,
              scale: scale,
              pageHeight: height,
              pageNumber: widget.pageIndex + 1,
              pageCount: state.doc.pages.length,
            ),
          // Deselect when tapping empty space (only when not drawing).
          if (!draw)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  state.stopEditing();
                  state.select(null);
                },
              ),
            ),
          // Elements.
          for (final e in widget.page.elements)
            IgnorePointer(
              ignoring: draw,
              child: ElementView(
                key: ValueKey(e.id),
                element: e,
                scale: scale,
                pageWpt: widget.size.ptWidth,
                pageHpt: widget.size.ptHeight,
              ),
            ),
          // Committed strokes.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: StrokePainter(widget.page.strokes, scale),
              ),
            ),
          ),
          // Drawing surface (captures pointer while Draw tool is active).
          if (draw)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) =>
                    setState(() => _current..clear()..add(d.localPosition / scale)),
                onPanUpdate: (d) =>
                    setState(() => _current.add(d.localPosition / scale)),
                onPanEnd: (_) {
                  if (_current.length > 1) {
                    state.addStroke(Stroke(
                      color: state.eraser ? 0xFFFFFFFF : state.drawColor,
                      width: state.drawWidth,
                      eraser: state.eraser,
                      points: List<Offset>.from(_current),
                    ));
                  }
                  setState(_current.clear);
                },
                child: CustomPaint(
                  painter: StrokePainter([
                    if (_current.length > 1)
                      Stroke(
                        color: state.eraser ? 0xFFBBBBBB : state.drawColor,
                        width: state.drawWidth,
                        points: _current,
                      ),
                  ], scale),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints committed / in-progress freehand strokes.
class StrokePainter extends CustomPainter {
  StrokePainter(this.strokes, this.scale);
  final List<Stroke> strokes;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length < 2) continue;
      final paint = Paint()
        ..color = Color(s.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(s.points.first.dx * scale, s.points.first.dy * scale);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter old) => true;
}

/// Paints the dashed margin guide from the document's 4 margins.
class MarginPainter extends CustomPainter {
  MarginPainter(this.doc, this.scale);
  final TestDocument doc;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      doc.marginLeft * scale,
      doc.marginTop * scale,
      size.width - doc.marginRight * scale,
      size.height - doc.marginBottom * scale,
    );
    final paint = Paint()
      ..color = const Color(0x559AA0A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const dash = 5.0, gap = 4.0;
    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      if (total == 0) return;
      final dir = (b - a) / total;
      var d = 0.0;
      while (d < total) {
        final s = a + dir * d;
        final e = a + dir * (d + dash).clamp(0, total).toDouble();
        canvas.drawLine(s, e, paint);
        d += dash + gap;
      }
    }

    line(rect.topLeft, rect.topRight);
    line(rect.topRight, rect.bottomRight);
    line(rect.bottomRight, rect.bottomLeft);
    line(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(covariant MarginPainter old) => true;
}
