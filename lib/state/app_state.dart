import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/question_bank.dart';
import '../models/question.dart';
import '../models/test_paper.dart';

/// Central store for the question bank and the paper being built.
class AppState extends ChangeNotifier {
  AppState() {
    _bank = buildQuestionBank();
  }

  static const _uuid = Uuid();

  late final List<Question> _bank;
  final TestPaper paper = TestPaper();

  List<Question> get bank => List.unmodifiable(_bank);

  List<String> get subjects {
    final set = <String>{for (final q in _bank) q.subject};
    final list = set.toList()..sort();
    return list;
  }

  List<String> get grades {
    final set = <String>{for (final q in _bank) q.grade};
    final list = set.toList()..sort();
    return list;
  }

  /// Filtered view of the bank used by the browser screen.
  List<Question> filteredBank({
    String? subject,
    String? grade,
    QuestionType? type,
    String search = '',
  }) {
    final query = search.trim().toLowerCase();
    return _bank.where((q) {
      if (subject != null && subject != 'All' && q.subject != subject) {
        return false;
      }
      if (grade != null && grade != 'All' && q.grade != grade) return false;
      if (type != null && q.type != type) return false;
      if (query.isNotEmpty && !q.text.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---- Paper editing -------------------------------------------------------

  /// Adds a fresh copy of a bank question to the paper.
  void addToPaper(Question source) {
    paper.questions.add(source.copyWith(id: _uuid.v4()));
    notifyListeners();
  }

  /// Adds a brand-new empty question of [type] for manual authoring.
  Question addBlank(QuestionType type) {
    final q = Question(
      id: _uuid.v4(),
      type: type,
      subject: paper.subject,
      grade: paper.grade,
      text: '',
      options: type == QuestionType.mcq ? ['', '', '', ''] : const [],
      wordBank:
          type == QuestionType.fillBlankWithOptions ? ['', '', ''] : const [],
      pairs: type == QuestionType.columnMatch
          ? [MatchPair(left: '', right: ''), MatchPair(left: '', right: '')]
          : null,
      isTrue: type == QuestionType.trueFalse ? true : null,
      marks: type == QuestionType.longQuestion ? 5 : 1,
    );
    paper.questions.add(q);
    notifyListeners();
    return q;
  }

  void removeFromPaper(String id) {
    paper.questions.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  void duplicate(String id) {
    final index = paper.questions.indexWhere((q) => q.id == id);
    if (index == -1) return;
    paper.questions
        .insert(index + 1, paper.questions[index].copyWith(id: _uuid.v4()));
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = paper.questions.removeAt(oldIndex);
    paper.questions.insert(newIndex, item);
    notifyListeners();
  }

  void clearPaper() {
    paper.questions.clear();
    notifyListeners();
  }

  /// Adds a curated mix of questions so the user instantly has a full paper.
  void quickFill({String? subject, String? grade}) {
    final pool = filteredBank(subject: subject, grade: grade);
    if (pool.isEmpty) return;
    final byType = <QuestionType, List<Question>>{};
    for (final q in pool) {
      byType.putIfAbsent(q.type, () => []).add(q);
    }
    paper.questions.clear();
    for (final entry in byType.entries) {
      for (final q in entry.value.take(4)) {
        paper.questions.add(q.copyWith(id: _uuid.v4()));
      }
    }
    notifyListeners();
  }

  /// Notifies listeners after an in-place edit of a paper question.
  void touch() => notifyListeners();

  void updatePaperHeader() => notifyListeners();
}
