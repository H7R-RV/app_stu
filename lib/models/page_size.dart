import 'package:pdf/pdf.dart';

/// Supported page sizes for the canvas / export.
enum PaperSize { a4, a5, letter, legal }

extension PaperSizeInfo on PaperSize {
  String get label {
    switch (this) {
      case PaperSize.a4:
        return 'A4';
      case PaperSize.a5:
        return 'A5';
      case PaperSize.letter:
        return 'Letter';
      case PaperSize.legal:
        return 'Legal';
    }
  }

  String get dimensionLabel {
    switch (this) {
      case PaperSize.a4:
        return '210 × 297 mm';
      case PaperSize.a5:
        return '148 × 210 mm';
      case PaperSize.letter:
        return '8.5 × 11 in';
      case PaperSize.legal:
        return '8.5 × 14 in';
    }
  }

  PdfPageFormat get pdfFormat {
    switch (this) {
      case PaperSize.a4:
        return PdfPageFormat.a4;
      case PaperSize.a5:
        return PdfPageFormat.a5;
      case PaperSize.letter:
        return PdfPageFormat.letter;
      case PaperSize.legal:
        return PdfPageFormat.legal;
    }
  }

  /// Page dimensions in PDF points (1/72 inch) — the canvas coordinate unit.
  double get ptWidth => pdfFormat.width;
  double get ptHeight => pdfFormat.height;

  // Page setup for the .docx export, in twips (1/1440 inch).
  int get docxWidthTwips => (ptWidth * 20).round();
  int get docxHeightTwips => (ptHeight * 20).round();
}
