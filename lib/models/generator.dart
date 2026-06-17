import 'dart:math';

import 'question.dart';

/// Difficulty buckets used for filtering the source pool.
enum Difficulty { any, easy, medium, hard }

/// Heuristic difficulty for a bank question (the bank isn't hand-tagged).
Difficulty difficultyOf(Question q) {
  switch (q.type) {
    case QuestionType.longQuestion:
      return Difficulty.hard;
    case QuestionType.shortQuestion:
    case QuestionType.columnMatch:
      return Difficulty.medium;
    default:
      return Difficulty.easy;
  }
}

/// One section of the blueprint (e.g. "Section A — 10 MCQs × 1 mark").
class SectionSpec {
  SectionSpec({
    required this.name,
    required this.type,
    this.count = 5,
    this.marksEach = 1,
    String? instruction,
  }) : instruction = instruction ?? _defaultInstruction(type);

  String name;
  QuestionType type;
  int count;
  int marksEach;
  String instruction;

  int get sectionMarks => count * marksEach;

  static String _defaultInstruction(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
        return 'Choose the correct option.';
      case QuestionType.trueFalse:
        return 'Write True or False.';
      case QuestionType.fillBlank:
      case QuestionType.fillBlankWithOptions:
        return 'Fill in the blanks.';
      case QuestionType.shortQuestion:
        return 'Answer briefly.';
      case QuestionType.longQuestion:
        return 'Answer in detail.';
      case QuestionType.columnMatch:
        return 'Match column A with column B.';
      case QuestionType.preschoolImage:
        return 'Look at the picture and answer.';
    }
  }
}

/// The blueprint the user configures in the wizard.
class GeneratorConfig {
  String schoolName = 'City Public School';
  String title = 'First Term Examination';
  String subject = 'All';
  String grade = 'All';
  String timeAllowed = '2 Hours';
  String instructions = 'Attempt all questions. Write neatly.';
  Difficulty difficulty = Difficulty.any;

  int sets = 1; // A, B, C ...
  bool shuffleQuestions = true;
  bool shuffleOptions = true;
  bool answerKey = true;

  final List<SectionSpec> sections = [
    SectionSpec(name: 'Section A', type: QuestionType.mcq, count: 5, marksEach: 1),
    SectionSpec(
        name: 'Section B',
        type: QuestionType.shortQuestion,
        count: 4,
        marksEach: 2),
    SectionSpec(
        name: 'Section C',
        type: QuestionType.longQuestion,
        count: 2,
        marksEach: 5),
  ];

  int get totalMarks =>
      sections.fold(0, (s, sec) => s + sec.sectionMarks);
}

class GeneratedSection {
  GeneratedSection(this.spec, this.questions);
  final SectionSpec spec;
  final List<Question> questions;
}

class GeneratedSet {
  GeneratedSet(this.label, this.sections);
  final String label; // "A", "B", ...
  final List<GeneratedSection> sections;
}

class GeneratedPaper {
  GeneratedPaper(this.config, this.sets);
  final GeneratorConfig config;
  final List<GeneratedSet> sets;
}

/// Builds a paper from the blueprint: selects non-repeating questions per
/// section, then produces [config.sets] shuffled variants (Set A/B/C…).
GeneratedPaper generatePaper(GeneratorConfig config, List<Question> bank) {
  final rng = Random();

  bool matches(Question q, QuestionType type) {
    if (q.type != type) return false;
    if (config.subject != 'All' && q.subject != config.subject) return false;
    if (config.grade != 'All' && q.grade != config.grade) return false;
    if (config.difficulty != Difficulty.any &&
        difficultyOf(q) != config.difficulty) {
      return false;
    }
    return true;
  }

  // Base selection (shared across sets), no repetition within the paper.
  final used = <String>{};
  final baseSelections = <List<Question>>[];
  for (final sec in config.sections) {
    final pool = bank.where((q) => matches(q, sec.type) && !used.contains(q.id)).toList()
      ..shuffle(rng);
    final picked = pool.take(sec.count).toList();
    for (final q in picked) {
      used.add(q.id);
    }
    baseSelections.add(picked);
  }

  final sets = <GeneratedSet>[];
  for (var s = 0; s < config.sets.clamp(1, 6); s++) {
    final label = String.fromCharCode(65 + s);
    final sections = <GeneratedSection>[];
    for (var i = 0; i < config.sections.length; i++) {
      final spec = config.sections[i];
      var qs = baseSelections[i]
          .map((q) => q.copyWith(id: '${q.id}_$label'))
          .toList();

      // Shuffle question order for sets after A.
      if (config.shuffleQuestions && s > 0) qs.shuffle(rng);

      // Shuffle MCQ options (keeping the correct answer tracked).
      if (config.shuffleOptions && (s > 0)) {
        for (final q in qs) {
          if (q.type == QuestionType.mcq && q.options.length > 1) {
            final correct =
                (q.correctOption != null && q.correctOption! < q.options.length)
                    ? q.options[q.correctOption!]
                    : null;
            q.options.shuffle(rng);
            if (correct != null) q.correctOption = q.options.indexOf(correct);
          }
        }
      }
      sections.add(GeneratedSection(spec, qs));
    }
    sets.add(GeneratedSet(label, sections));
  }

  return GeneratedPaper(config, sets);
}
