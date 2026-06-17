import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../models/doc_element.dart';

/// Loads and caches the bundled TTF fonts as PDF fonts for export.
class PdfFonts {
  static final Map<String, pw.Font> _cache = {};

  static Future<pw.Font> load(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;
    final data = await rootBundle.load(asset);
    final font = pw.Font.ttf(data);
    _cache[asset] = font;
    return font;
  }

  static Future<pw.Font> forElement(DocElement e) {
    return load(fontAsset(e.fontFamily, bold: e.bold, italic: e.italic));
  }
}
