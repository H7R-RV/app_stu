import 'dart:typed_data';

import 'package:flutter/material.dart';

/// The kinds of free-floating items that can be placed on the canvas.
enum ElementType { text, image, rect, ellipse, line, polygon }

/// Vector shape varieties (drawn identically on screen and in the PDF).
enum ShapeKind { triangle, diamond, pentagon, hexagon, star, arrow }

/// The bundled font families available in the editor.
const List<String> kFontFamilies = [
  'Lato',
  'Poppins',
  'PT Sans',
  'PT Serif',
  'Lobster',
  'Pacifico',
];

/// Families that only ship a regular weight (no bold/italic variants).
const Set<String> _regularOnly = {'Lobster', 'Pacifico'};

/// Resolves a bundled font asset path for a family + weight/style.
String fontAsset(String family, {bool bold = false, bool italic = false}) {
  const base = {
    'Lato': 'Lato',
    'Poppins': 'Poppins',
    'PT Sans': 'PTSans',
    'PT Serif': 'PTSerif',
    'Lobster': 'Lobster',
    'Pacifico': 'Pacifico',
  };
  final b = base[family] ?? 'Lato';
  String variant;
  if (_regularOnly.contains(family)) {
    variant = 'Regular';
  } else if (bold && italic) {
    variant = 'BoldItalic';
  } else if (bold) {
    variant = 'Bold';
  } else if (italic) {
    variant = 'Italic';
  } else {
    variant = 'Regular';
  }
  return 'assets/fonts/$b-$variant.ttf';
}

/// A single free-positioned element on the page.
///
/// Geometry is stored in PDF points (1/72") so the on-screen canvas and the
/// exported PDF line up exactly; the screen simply scales by pageWidth/ptWidth.
class DocElement {
  DocElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.rotation = 0,
    this.text = '',
    this.fontFamily = 'Lato',
    this.fontSize = 16,
    this.color = 0xFF111111,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.align = TextAlign.left,
    this.fill,
    this.strokeColor = 0xFF111111,
    this.strokeWidth = 0,
    this.opacity = 1.0,
    this.imageBytes,
    this.shape = ShapeKind.star,
  });

  final String id;
  ElementType type;

  double x;
  double y;
  double w;
  double h;
  double rotation; // degrees

  // Text
  String text;
  String fontFamily;
  double fontSize;
  int color; // ARGB
  bool bold;
  bool italic;
  bool underline;
  TextAlign align;

  // Fill / stroke (shapes, or text background when [fill] != null)
  int? fill; // ARGB
  int strokeColor; // ARGB
  double strokeWidth;
  double opacity;

  // Image
  Uint8List? imageBytes;

  // Polygon shape variety
  ShapeKind shape;

  Color get textColor => Color(color);
  Color? get fillColor => fill == null ? null : Color(fill!);
  Color get stroke => Color(strokeColor);

  bool get isText => type == ElementType.text;

  DocElement copy({required String id}) {
    return DocElement(
      id: id,
      type: type,
      x: x + 12,
      y: y + 12,
      w: w,
      h: h,
      rotation: rotation,
      text: text,
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      bold: bold,
      italic: italic,
      underline: underline,
      align: align,
      fill: fill,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      opacity: opacity,
      imageBytes: imageBytes,
      shape: shape,
    );
  }
}
