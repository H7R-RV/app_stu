import 'dart:typed_data';

/// The kinds of questions the generator can build and export.
enum QuestionType {
  mcq,
  shortQuestion,
  longQuestion,
  fillBlank,
  fillBlankWithOptions,
  columnMatch,
  trueFalse,
  preschoolImage,
}

extension QuestionTypeInfo on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.mcq:
        return 'MCQs';
      case QuestionType.shortQuestion:
        return 'Short Question';
      case QuestionType.longQuestion:
        return 'Long Question';
      case QuestionType.fillBlank:
        return 'Fill in the Blanks';
      case QuestionType.fillBlankWithOptions:
        return 'Fill in the Blanks (Word Bank)';
      case QuestionType.columnMatch:
        return 'Column / Collins Match';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.preschoolImage:
        return 'Pre-School (Picture)';
    }
  }

  String get shortLabel {
    switch (this) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.shortQuestion:
        return 'Short';
      case QuestionType.longQuestion:
        return 'Long';
      case QuestionType.fillBlank:
        return 'Fill Blank';
      case QuestionType.fillBlankWithOptions:
        return 'Word Bank';
      case QuestionType.columnMatch:
        return 'Match';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.preschoolImage:
        return 'Picture';
    }
  }
}

/// A single Column-A -> Column-B matching pair.
class MatchPair {
  MatchPair({required this.left, required this.right});

  String left;
  String right;

  MatchPair copy() => MatchPair(left: left, right: right);
}

/// A flexible question model that covers every supported [QuestionType].
///
/// Only the fields relevant to a given type are used; the rest stay empty.
class Question {
  Question({
    required this.id,
    required this.type,
    required this.subject,
    required this.grade,
    required this.text,
    this.options = const [],
    this.correctOption,
    this.answer = '',
    this.wordBank = const [],
    List<MatchPair>? pairs,
    this.isTrue,
    this.emoji,
    this.imageBytes,
    this.marks = 1,
  }) : pairs = pairs ?? [];

  final String id;
  QuestionType type;
  String subject;
  String grade;
  String text;

  /// MCQ choices.
  List<String> options;

  /// Index into [options] that is correct (MCQ).
  int? correctOption;

  /// Free-text answer (short / long / fill-blank answer key / true-false note).
  String answer;

  /// The word bank shown at the top for "fill in the blanks with options".
  List<String> wordBank;

  /// Column / Collins matching pairs.
  List<MatchPair> pairs;

  /// True/False correct value.
  bool? isTrue;

  /// Optional emoji used as a lightweight picture for pre-school items.
  String? emoji;

  /// Optional attached image (embedded into PDF / Word exports).
  Uint8List? imageBytes;

  int marks;

  /// Deep copy so editing a question placed on a paper never mutates the bank.
  Question copyWith({String? id}) {
    return Question(
      id: id ?? this.id,
      type: type,
      subject: subject,
      grade: grade,
      text: text,
      options: List<String>.from(options),
      correctOption: correctOption,
      answer: answer,
      wordBank: List<String>.from(wordBank),
      pairs: pairs.map((p) => p.copy()).toList(),
      isTrue: isTrue,
      emoji: emoji,
      imageBytes: imageBytes,
      marks: marks,
    );
  }
}
