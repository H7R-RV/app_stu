import 'package:flutter_test/flutter_test.dart';

import 'package:simple_demo/data/question_bank.dart';
import 'package:simple_demo/export/docx_export.dart';
import 'package:simple_demo/export/pdf_export.dart';
import 'package:simple_demo/main.dart';
import 'package:simple_demo/models/test_paper.dart';

void main() {
  testWidgets('App boots and shows the builder', (WidgetTester tester) async {
    await tester.pumpWidget(const TestGeneratorApp());
    await tester.pumpAndSettle();

    expect(find.text('Test Generator'), findsOneWidget);
    expect(find.text('Add question'), findsOneWidget);
  });

  test('Question bank is populated with many questions', () {
    final bank = buildQuestionBank();
    expect(bank.length, greaterThan(80));
  });

  test('PDF export produces a non-empty document', () async {
    final paper = TestPaper();
    final bank = buildQuestionBank();
    paper.questions.addAll(bank.take(12).map((q) => q.copyWith()));
    final bytes = await PdfExporter.build(paper);
    expect(bytes.lengthInBytes, greaterThan(500));
  });

  test('DOCX export produces a valid zip package', () {
    final paper = TestPaper();
    final bank = buildQuestionBank();
    paper.questions.addAll(bank.take(12).map((q) => q.copyWith()));
    final bytes = DocxExporter.build(paper);
    // ZIP packages start with the "PK" magic bytes.
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4B);
    expect(bytes.lengthInBytes, greaterThan(300));
  });
}
