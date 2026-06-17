import 'package:pdf/pdf.dart';

import 'question.dart';

/// Supported page sizes shown in the builder and used for export.
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

  /// Width / height ratio used to draw the on-screen page preview.
  double get aspectRatio {
    switch (this) {
      case PaperSize.a4:
        return 210 / 297;
      case PaperSize.a5:
        return 148 / 210;
      case PaperSize.letter:
        return 8.5 / 11;
      case PaperSize.legal:
        return 8.5 / 14;
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

  /// Page width in twips (1/1440 inch) for the .docx page setup.
  int get docxWidthTwips {
    switch (this) {
      case PaperSize.a4:
        return 11906;
      case PaperSize.a5:
        return 8391;
      case PaperSize.letter:
        return 12240;
      case PaperSize.legal:
        return 12240;
    }
  }

  int get docxHeightTwips {
    switch (this) {
      case PaperSize.a4:
        return 16838;
      case PaperSize.a5:
        return 11906;
      case PaperSize.letter:
        return 15840;
      case PaperSize.legal:
        return 20160;
    }
  }
}

/// All the header / metadata for the paper plus the ordered questions on it.
class TestPaper {
  TestPaper();

  String schoolName = 'City Public School';
  String title = 'First Term Examination';
  String subject = 'General';
  String grade = 'Grade 5';
  String teacher = '';
  String timeAllowed = '2 Hours';
  String instructions =
      'Attempt all questions. Write neatly. Marks are given against each question.';
  PaperSize size = PaperSize.a4;
  bool showAnswerKey = false;

  /// The ordered list of questions placed on the paper.
  final List<Question> questions = [];

  int get totalMarks =>
      questions.fold(0, (sum, q) => sum + q.marks);
}
