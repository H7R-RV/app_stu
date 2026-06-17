import 'dart:math' as math;

import '../models/question.dart';
import '../models/test_paper.dart';

/// Shared layout constants used by both the estimator and the renderer so the
/// on-screen pages match the computed page breaks as closely as possible.
class LayoutConst {
  static const double bodyFont = 13.0;
  static const double lineHeight = 20.0;
  static const double optionHeight = 22.0;
  static const double blankLineHeight = 27.0;
  static const double cardPaddingV = 18.0; // top + bottom of a question card
  static const double cardPaddingH = 26.0;
  static const double questionGap = 12.0;
}

/// Pixel geometry of a single page for the current paper + available width.
class PaperMetrics {
  PaperMetrics({required TestPaper paper, required double availableWidth}) {
    pageWidth = availableWidth;
    pxPerMm = pageWidth / paper.size.widthMm;
    pageHeight = pageWidth * (paper.size.heightMm / paper.size.widthMm);
    marginPx = paper.marginMm * pxPerMm;
    paddingPx = paper.paddingMm * pxPerMm;
    contentWidth = pageWidth - 2 * marginPx - 2 * paddingPx;
    contentHeight = pageHeight - 2 * marginPx - 2 * paddingPx;
  }

  late final double pageWidth;
  late final double pageHeight;
  late final double pxPerMm;
  late final double marginPx;
  late final double paddingPx;
  late final double contentWidth;
  late final double contentHeight;

  double get inset => marginPx + paddingPx;
}

/// Rough but generous (over-)estimate of a question's rendered height so that
/// content breaks onto a new page slightly early rather than overflowing.
double estimateQuestionHeight(Question q, double contentWidth) {
  final charWidth = LayoutConst.bodyFont * 0.52;
  final charsPerLine = math.max(12, contentWidth / charWidth);

  int linesOf(String text) =>
      math.max(1, (text.length / charsPerLine).ceil());

  var h = LayoutConst.cardPaddingV;
  // The bold "Q. <text>" header row (leave room for the marks chip width).
  h += linesOf(q.text) * LayoutConst.lineHeight + 4;

  switch (q.type) {
    case QuestionType.mcq:
      for (final o in q.options) {
        h += math.max(1, linesOf(o)) * LayoutConst.optionHeight;
      }
      break;
    case QuestionType.trueFalse:
      h += LayoutConst.lineHeight;
      break;
    case QuestionType.shortQuestion:
      h += 2 * LayoutConst.blankLineHeight;
      break;
    case QuestionType.longQuestion:
      h += 5 * LayoutConst.blankLineHeight;
      break;
    case QuestionType.fillBlank:
      h += 6;
      break;
    case QuestionType.fillBlankWithOptions:
      h += 2 * LayoutConst.lineHeight + 14;
      break;
    case QuestionType.columnMatch:
      h += (q.pairs.length + 1) * LayoutConst.lineHeight;
      break;
    case QuestionType.preschoolImage:
      h += (q.imageBytes != null ? 100 : 78);
      h += LayoutConst.optionHeight;
      break;
  }
  return (h + LayoutConst.questionGap) * 1.06;
}

double estimateHeaderHeight(TestPaper paper) {
  final c = paper.header;
  var h = 18.0;
  if (c.showSchool) h += 30;
  if (c.showTitle) h += 24;
  if (c.showSubject || c.showClass) h += 20;
  if (c.showTime || c.showMarks) h += 20;
  h += 26; // name / roll line + divider
  if (c.showInstructions) h += 34;
  if (c.showLogo) h += 8;
  return h;
}

/// Splits the question indices into pages that fit the content area.
List<List<int>> paginate(TestPaper paper, PaperMetrics m) {
  final pages = <List<int>>[];
  var current = <int>[];
  var used = estimateHeaderHeight(paper); // header sits on the first page

  for (var i = 0; i < paper.questions.length; i++) {
    final h = estimateQuestionHeight(paper.questions[i], m.contentWidth);
    if (current.isNotEmpty && used + h > m.contentHeight) {
      pages.add(current);
      current = <int>[];
      used = 0;
    }
    current.add(i);
    used += h;
  }
  if (current.isNotEmpty || pages.isEmpty) pages.add(current);
  return pages;
}
