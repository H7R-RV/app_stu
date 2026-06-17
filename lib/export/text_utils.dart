import '../models/question.dart';

/// Map of common non-Latin1 glyphs to ASCII equivalents so the built-in PDF
/// fonts (which only support WinAnsi/Latin1) never crash on layout.
const Map<String, String> _replacements = {
  'π': 'pi',
  '≥': '>=',
  '≤': '<=',
  '≠': '!=',
  '→': '->',
  '←': '<-',
  '↔': '<->',
  '⅓': '1/3',
  '⅔': '2/3',
  '⅛': '1/8',
  '⅜': '3/8',
  '☐': '[ ]',
  '✓': '(tick)',
  '✗': '(x)',
  '•': '-',
  '–': '-',
  '—': '-',
  '“': '"',
  '”': '"',
  '‘': "'",
  '’': "'",
  '…': '...',
};

/// Returns a version of [input] safe for the standard PDF fonts: known symbols
/// are transliterated and any remaining non-Latin1 runes (e.g. emoji) dropped.
String asciiSafe(String input) {
  var s = input;
  _replacements.forEach((k, v) => s = s.replaceAll(k, v));
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    if (rune <= 0xFF) {
      buffer.writeCharCode(rune);
    } else {
      // Unsupported glyph (emoji etc.) – skip to avoid font crashes.
    }
  }
  return buffer.toString();
}

/// Escapes a string for safe inclusion in OOXML / XML (.docx).
String xmlEscape(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

/// Human-readable answer for a question, used in the answer key.
String answerOf(Question q) {
  switch (q.type) {
    case QuestionType.mcq:
      if (q.correctOption != null &&
          q.correctOption! >= 0 &&
          q.correctOption! < q.options.length) {
        return '(${String.fromCharCode(65 + q.correctOption!)}) '
            '${q.options[q.correctOption!]}';
      }
      return '-';
    case QuestionType.trueFalse:
      return q.isTrue == null ? '-' : (q.isTrue! ? 'True' : 'False');
    case QuestionType.columnMatch:
      return q.pairs
          .asMap()
          .entries
          .map((e) => '${e.key + 1}-${String.fromCharCode(97 + e.key)}')
          .join(', ');
    default:
      return q.answer.isEmpty ? '-' : q.answer;
  }
}
