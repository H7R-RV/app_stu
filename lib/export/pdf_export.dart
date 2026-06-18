import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show TextAlign;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/doc_element.dart';
import '../models/document.dart';
import '../models/page_size.dart';
import '../widgets/shape_geometry.dart';
import 'font_loader.dart';

/// Renders the canvas document to a pixel-accurate PDF (positioned elements,
/// embedded fonts).
class PdfExporter {
  static Future<Uint8List> build(TestDocument doc) async {
    // Preload every font variant the document needs.
    final fonts = <String, pw.Font>{};
    for (final page in doc.pages) {
      for (final e in page.elements) {
        if (e.isText) {
          final asset = fontAsset(e.fontFamily, bold: e.bold, italic: e.italic);
          if (!fonts.containsKey(asset)) {
            try {
              fonts[asset] = await PdfFonts.load(asset);
            } catch (_) {
              // Fall back to the built-in PDF font if the asset is unavailable.
            }
          }
        }
      }
    }

    final pdf = pw.Document();
    final format = doc.size.pdfFormat;

    for (final page in doc.pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            final pageIndex = doc.pages.indexOf(page);
            return pw.SizedBox(
              width: format.width,
              height: format.height,
              child: pw.Stack(
                children: [
                  if (pageIndex == 0 && doc.header.enabled)
                    _pdfHeader(doc, fonts),
                  for (final e in page.elements) _positioned(e, fonts),
                  if (page.strokes.isNotEmpty)
                    pw.Positioned(
                      left: 0,
                      top: 0,
                      child: pw.CustomPaint(
                        size: PdfPoint(format.width, format.height),
                        painter: (canvas, size) {
                          for (final s in page.strokes) {
                            if (s.points.length < 2) continue;
                            canvas
                              ..setStrokeColor(PdfColor.fromInt(s.color))
                              ..setLineWidth(s.width)
                              ..moveTo(s.points.first.dx,
                                  size.y - s.points.first.dy);
                            for (final p in s.points.skip(1)) {
                              canvas.lineTo(p.dx, size.y - p.dy);
                            }
                            canvas.strokePath();
                          }
                        },
                      ),
                    ),
                  if (doc.footer.enabled)
                    _pdfFooter(doc, fonts, pageIndex + 1, doc.pages.length),
                ],
              ),
            );
          },
        ),
      );
    }
    return pdf.save();
  }

  static pw.Widget _pdfHeader(dynamic doc, Map<String, pw.Font> fonts) {
    final h = doc.header;
    return pw.Positioned(
      left: doc.marginLeft,
      top: doc.marginTop,
      right: doc.marginRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(h.school,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text(h.title,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 3),
          pw.Text(h.subject, style: const pw.TextStyle(fontSize: 9.5)),
          pw.Text(h.meta, style: const pw.TextStyle(fontSize: 9.5)),
          pw.Divider(thickness: 1),
          if (h.studentGrid)
            pw.Text('Name: ____________   Roll No: ______   Section: ____',
                style: const pw.TextStyle(fontSize: 9.5)),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter(
      dynamic doc, Map<String, pw.Font> fonts, int n, int total) {
    final f = doc.footer;
    return pw.Positioned(
      left: doc.marginLeft,
      right: doc.marginRight,
      bottom: (doc.marginBottom - 18).clamp(2, doc.marginBottom).toDouble(),
      child: pw.Column(
        children: [
          pw.Divider(thickness: 0.8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(f.text, style: const pw.TextStyle(fontSize: 9)),
              if (f.pageNumber)
                pw.Text('Page $n of $total',
                    style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _positioned(DocElement e, Map<String, pw.Font> fonts) {
    pw.Widget child = _element(e, fonts);
    if (e.rotation != 0) {
      child = pw.Transform.rotate(angle: e.rotation * math.pi / 180, child: child);
    }
    if (e.opacity < 1) {
      child = pw.Opacity(opacity: e.opacity, child: child);
    }
    return pw.Positioned(left: e.x, top: e.y, child: child);
  }

  static pw.Widget _element(DocElement e, Map<String, pw.Font> fonts) {
    switch (e.type) {
      case ElementType.text:
        final asset = fontAsset(e.fontFamily, bold: e.bold, italic: e.italic);
        return pw.Container(
          width: e.w,
          height: e.h,
          color: e.fill == null ? null : PdfColor.fromInt(e.fill!),
          alignment: _align(e.align),
          child: pw.Text(
            e.text,
            textAlign: _textAlign(e.align),
            style: pw.TextStyle(
              font: fonts[asset],
              fontSize: e.fontSize,
              color: PdfColor.fromInt(e.color),
              decoration: e.underline
                  ? pw.TextDecoration.underline
                  : pw.TextDecoration.none,
              letterSpacing: e.letterSpacing,
              lineSpacing: 1.5,
            ),
          ),
        );
      case ElementType.image:
        if (e.imageBytes == null) {
          return pw.SizedBox(width: e.w, height: e.h);
        }
        return pw.Image(pw.MemoryImage(e.imageBytes!),
            width: e.w, height: e.h, fit: pw.BoxFit.fill);
      case ElementType.rect:
        return pw.Container(
          width: e.w,
          height: e.h,
          decoration: pw.BoxDecoration(
            color: e.fill == null ? null : PdfColor.fromInt(e.fill!),
            border: e.strokeWidth > 0
                ? pw.Border.all(
                    color: PdfColor.fromInt(e.strokeColor),
                    width: e.strokeWidth)
                : null,
          ),
        );
      case ElementType.ellipse:
        return pw.Container(
          width: e.w,
          height: e.h,
          decoration: pw.BoxDecoration(
            color: e.fill == null ? null : PdfColor.fromInt(e.fill!),
            borderRadius: pw.BorderRadius.all(
                pw.Radius.circular(math.min(e.w, e.h) / 2)),
            border: e.strokeWidth > 0
                ? pw.Border.all(
                    color: PdfColor.fromInt(e.strokeColor),
                    width: e.strokeWidth)
                : null,
          ),
        );
      case ElementType.line:
        return pw.Container(
            width: e.w, height: e.h, color: PdfColor.fromInt(e.strokeColor));
      case ElementType.polygon:
        final pts = shapePoints(e.shape);
        final hasFill = e.fill != null;
        final hasStroke = e.strokeWidth > 0;
        return pw.CustomPaint(
          size: PdfPoint(e.w, e.h),
          painter: (canvas, size) {
            for (var i = 0; i < pts.length; i++) {
              final x = pts[i][0] * size.x;
              final y = size.y - pts[i][1] * size.y; // flip to PDF y-up
              if (i == 0) {
                canvas.moveTo(x, y);
              } else {
                canvas.lineTo(x, y);
              }
            }
            canvas.closePath();
            if (hasFill) canvas.setFillColor(PdfColor.fromInt(e.fill!));
            if (hasStroke) {
              canvas.setStrokeColor(PdfColor.fromInt(e.strokeColor));
              canvas.setLineWidth(e.strokeWidth);
            }
            if (hasFill && hasStroke) {
              canvas.fillAndStrokePath();
            } else if (hasFill) {
              canvas.fillPath();
            } else {
              canvas.strokePath();
            }
          },
        );
    }
  }

  static pw.Alignment _align(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return pw.Alignment.topCenter;
      case TextAlign.right:
      case TextAlign.end:
        return pw.Alignment.topRight;
      default:
        return pw.Alignment.topLeft;
    }
  }

  static pw.TextAlign _textAlign(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return pw.TextAlign.center;
      case TextAlign.right:
      case TextAlign.end:
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }
}
