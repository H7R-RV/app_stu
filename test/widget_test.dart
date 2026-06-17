import 'package:flutter_test/flutter_test.dart';

import 'package:simple_demo/data/question_bank.dart';
import 'package:simple_demo/export/docx_export.dart';
import 'package:simple_demo/export/pdf_export.dart';
import 'package:simple_demo/main.dart';
import 'package:simple_demo/models/doc_element.dart';
import 'package:simple_demo/models/document.dart';
import 'package:simple_demo/models/generator.dart';

TestDocument _sampleDoc() {
  final doc = TestDocument();
  doc.pages.first.elements.addAll([
    DocElement(
        id: 't1',
        type: ElementType.text,
        x: 40,
        y: 40,
        w: 400,
        h: 30,
        text: 'Sample Heading',
        fontSize: 22,
        bold: true),
    DocElement(
        id: 'r1', type: ElementType.rect, x: 40, y: 90, w: 200, h: 60, fill: 0xFFE3E7FF),
    DocElement(
        id: 't2',
        type: ElementType.text,
        x: 40,
        y: 160,
        w: 400,
        h: 60,
        text: 'Q1. What is 2 + 2?\n(A) 3  (B) 4  (C) 5'),
  ]);
  return doc;
}

void main() {
  testWidgets('App boots and shows the start screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TestGeneratorApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Test Paper Studio'), findsOneWidget);
    expect(find.text('Auto-Generate Paper'), findsOneWidget);
  });

  test('Paper generator builds sets with answer key', () {
    final bank = buildQuestionBank();
    final cfg = GeneratorConfig()..sets = 2;
    final paper = generatePaper(cfg, bank);
    expect(paper.sets.length, 2);
    expect(paper.sets.first.sections.isNotEmpty, true);
  });

  test('Question library is populated', () {
    expect(buildQuestionBank().length, greaterThan(80));
  });

  test('PDF export produces a non-empty document', () async {
    final bytes = await PdfExporter.build(_sampleDoc());
    expect(bytes.lengthInBytes, greaterThan(400));
  });

  test('DOCX export produces a valid zip package', () {
    final bytes = DocxExporter.build(_sampleDoc());
    expect(bytes[0], 0x50); // 'P'
    expect(bytes[1], 0x4B); // 'K'
    expect(bytes.lengthInBytes, greaterThan(300));
  });
}
