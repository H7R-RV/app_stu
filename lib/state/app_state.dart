import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/question_bank.dart';
import '../models/doc_element.dart';
import '../models/document.dart';
import '../models/page_size.dart';
import '../models/question.dart';

/// Central store for the canvas document plus the (read-only) question library.
class AppState extends ChangeNotifier {
  AppState() {
    _bank = buildQuestionBank();
  }

  static const _uuid = Uuid();

  late final List<Question> _bank;
  final TestDocument doc = TestDocument();

  int currentPage = 0;
  String? selectedId;
  String? editingId; // text element currently being edited

  DocPage get page => doc.pages[currentPage.clamp(0, doc.pages.length - 1)];

  DocElement? get selected {
    for (final p in doc.pages) {
      for (final e in p.elements) {
        if (e.id == selectedId) return e;
      }
    }
    return null;
  }

  // ---- Library -------------------------------------------------------------
  List<Question> get bank => List.unmodifiable(_bank);

  List<String> get subjects {
    final s = <String>{for (final q in _bank) q.subject}.toList()..sort();
    return s;
  }

  List<Question> filteredBank({
    String? subject,
    QuestionType? type,
    String search = '',
  }) {
    final q = search.trim().toLowerCase();
    return _bank.where((e) {
      if (subject != null && subject != 'All' && e.subject != subject) {
        return false;
      }
      if (type != null && e.type != type) return false;
      if (q.isNotEmpty && !e.text.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  // ---- Selection / editing -------------------------------------------------
  void select(String? id) {
    if (selectedId == id && editingId == null) return;
    selectedId = id;
    if (editingId != null && editingId != id) editingId = null;
    notifyListeners();
  }

  void startEditing(String id) {
    selectedId = id;
    editingId = id;
    notifyListeners();
  }

  void stopEditing() {
    if (editingId == null) return;
    editingId = null;
    notifyListeners();
  }

  /// Call after mutating a selected element's properties.
  void touch() => notifyListeners();

  // ---- Element creation ----------------------------------------------------
  double get _pw => doc.size.ptWidth;

  void _add(DocElement e) {
    page.elements.add(e);
    selectedId = e.id;
    editingId = null;
    notifyListeners();
  }

  double _cx(double w) => ((_pw - w) / 2).clamp(0, _pw);

  void addText({String text = 'Double-tap to edit', double fontSize = 16, bool bold = false}) {
    _add(DocElement(
      id: _uuid.v4(),
      type: ElementType.text,
      x: _cx(260),
      y: 90,
      w: 260,
      h: fontSize * 1.8 + 8,
      text: text,
      fontSize: fontSize,
      bold: bold,
    ));
  }

  void addHeading() =>
      addText(text: 'Heading', fontSize: 30, bold: true);

  void addImage(Uint8List bytes, {double aspect = 1}) {
    const w = 200.0;
    _add(DocElement(
      id: _uuid.v4(),
      type: ElementType.image,
      x: _cx(w),
      y: 90,
      w: w,
      h: w / (aspect == 0 ? 1 : aspect),
      imageBytes: bytes,
    ));
  }

  void addRect() {
    _add(DocElement(
      id: _uuid.v4(),
      type: ElementType.rect,
      x: _cx(180),
      y: 100,
      w: 180,
      h: 110,
      fill: 0xFFE3E7FF,
      strokeColor: 0xFF4F46E5,
      strokeWidth: 1,
    ));
  }

  void addEllipse() {
    _add(DocElement(
      id: _uuid.v4(),
      type: ElementType.ellipse,
      x: _cx(150),
      y: 100,
      w: 150,
      h: 150,
      fill: 0xFFFFE3EC,
      strokeColor: 0xFFEC4899,
      strokeWidth: 1,
    ));
  }

  void addLine() {
    _add(DocElement(
      id: _uuid.v4(),
      type: ElementType.line,
      x: _cx(240),
      y: 120,
      w: 240,
      h: 2,
      strokeColor: 0xFF111111,
      strokeWidth: 2,
    ));
  }

  /// Inserts a question from the library as a pre-formatted text block.
  void addFromQuestion(Question q) {
    final buffer = StringBuffer(q.text);
    switch (q.type) {
      case QuestionType.mcq:
        for (var i = 0; i < q.options.length; i++) {
          buffer.write('\n   (${String.fromCharCode(65 + i)}) ${q.options[i]}');
        }
        break;
      case QuestionType.trueFalse:
        buffer.write('\n   (   ) True     (   ) False');
        break;
      case QuestionType.fillBlankWithOptions:
        buffer.write('\n   [ ${q.wordBank.join('   ')} ]');
        break;
      case QuestionType.columnMatch:
        for (var i = 0; i < q.pairs.length; i++) {
          buffer.write(
              '\n   ${i + 1}. ${q.pairs[i].left}        (${String.fromCharCode(97 + i)}) ${q.pairs[i].right}');
        }
        break;
      case QuestionType.shortQuestion:
      case QuestionType.longQuestion:
      case QuestionType.fillBlank:
      case QuestionType.preschoolImage:
        break;
    }
    const w = 460.0;
    final lines = '\n'.allMatches(buffer.toString()).length + 1;
    _add(DocElement(
      id: _uuid.v4(),
      type: ElementType.text,
      x: _cx(w),
      y: 100,
      w: w,
      h: lines * 20.0 + 10,
      text: buffer.toString(),
      fontSize: 13,
    ));
  }

  // ---- Element ops ---------------------------------------------------------
  void delete(String id) {
    for (final p in doc.pages) {
      p.elements.removeWhere((e) => e.id == id);
    }
    if (selectedId == id) selectedId = null;
    if (editingId == id) editingId = null;
    notifyListeners();
  }

  void duplicate(String id) {
    for (final p in doc.pages) {
      final i = p.elements.indexWhere((e) => e.id == id);
      if (i != -1) {
        final copy = p.elements[i].copy(id: _uuid.v4());
        p.elements.add(copy);
        selectedId = copy.id;
        notifyListeners();
        return;
      }
    }
  }

  void _reorder(String id, bool forward) {
    for (final p in doc.pages) {
      final i = p.elements.indexWhere((e) => e.id == id);
      if (i == -1) continue;
      final ni = forward ? i + 1 : i - 1;
      if (ni < 0 || ni >= p.elements.length) return;
      final e = p.elements.removeAt(i);
      p.elements.insert(ni, e);
      notifyListeners();
      return;
    }
  }

  void bringForward(String id) => _reorder(id, true);
  void sendBackward(String id) => _reorder(id, false);

  // ---- Pages ---------------------------------------------------------------
  void addPage() {
    doc.pages.add(DocPage());
    currentPage = doc.pages.length - 1;
    selectedId = null;
    notifyListeners();
  }

  void deletePage(int index) {
    if (doc.pages.length <= 1) return;
    doc.pages.removeAt(index);
    currentPage = currentPage.clamp(0, doc.pages.length - 1);
    selectedId = null;
    notifyListeners();
  }

  void setCurrentPage(int index) {
    currentPage = index.clamp(0, doc.pages.length - 1);
    selectedId = null;
    notifyListeners();
  }

  void setSize(PaperSize size) {
    doc.size = size;
    notifyListeners();
  }
}
