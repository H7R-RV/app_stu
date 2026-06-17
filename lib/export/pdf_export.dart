import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/question.dart';
import '../models/test_paper.dart';
import 'text_utils.dart';

/// Builds the test paper as a PDF document.
class PdfExporter {
  static Future<Uint8List> build(TestPaper paper) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.base();

    doc.addPage(
      pw.MultiPage(
        pageFormat: paper.size.pdfFormat,
        theme: theme,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(asciiSafe(paper.title),
                    style: const pw.TextStyle(fontSize: 9)),
              ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        build: (ctx) => [
          _header(paper),
          pw.SizedBox(height: 8),
          for (var i = 0; i < paper.questions.length; i++)
            _question(paper.questions[i], i + 1),
          if (paper.showAnswerKey) ..._answerKey(paper),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(TestPaper paper) {
    pw.Widget line(String l, String r) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text(asciiSafe(l)), pw.Text(asciiSafe(r))],
        );
    final c = paper.header;
    final meta1 = <String>[
      if (c.showSubject) 'Subject: ${paper.subject}',
      if (c.showClass) 'Class: ${paper.grade}',
    ];
    final meta2 = <String>[
      if (c.showTime) 'Time: ${paper.timeAllowed}',
      if (c.showMarks) 'Total Marks: ${paper.totalMarks}',
    ];
    final student = <String>[
      if (c.showName) 'Name: ____________________',
      if (c.showRoll) 'Roll No: __________',
      if (c.showDate) 'Date: ${c.date.isEmpty ? '__________' : c.date}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (c.showSchool)
          pw.Center(
            child: pw.Text(asciiSafe(paper.schoolName),
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
        if (c.showTitle)
          pw.Center(
            child: pw.Text(asciiSafe(paper.title),
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ),
        pw.SizedBox(height: 6),
        if (meta1.isNotEmpty) line(meta1.first, meta1.length > 1 ? meta1[1] : ''),
        if (meta2.isNotEmpty) line(meta2.first, meta2.length > 1 ? meta2[1] : ''),
        pw.Divider(thickness: 1),
        if (student.isNotEmpty) pw.Text(student.join('      ')),
        if (c.showInstructions && paper.instructions.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text('Instructions: ${asciiSafe(paper.instructions)}',
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic, fontSize: 10)),
          ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  static pw.Widget _question(Question q, int number) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Q$number. ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Text(asciiSafe(q.text),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('(${q.marks})',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, top: 3),
            child: _body(q),
          ),
        ],
      ),
    );
  }

  static pw.Widget _body(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        String opt(int i) =>
            '(${String.fromCharCode(65 + i)})  ${asciiSafe(q.options[i])}';
        if (q.mcqLayout == McqLayout.row) {
          return pw.Wrap(
            spacing: 18,
            runSpacing: 3,
            children: [
              for (var i = 0; i < q.options.length; i++) pw.Text(opt(i)),
            ],
          );
        }
        if (q.mcqLayout == McqLayout.twoColumn) {
          final rows = <pw.Widget>[];
          for (var i = 0; i < q.options.length; i += 2) {
            rows.add(pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Text(opt(i))),
                pw.Expanded(
                    child: i + 1 < q.options.length
                        ? pw.Text(opt(i + 1))
                        : pw.SizedBox()),
              ],
            ));
          }
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows);
        }
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < q.options.length; i++) pw.Text(opt(i)),
          ],
        );
      case QuestionType.trueFalse:
        return pw.Text('(  ) True            (  ) False');
      case QuestionType.shortQuestion:
        return _blankLines(2);
      case QuestionType.longQuestion:
        return _blankLines(5);
      case QuestionType.fillBlank:
        return pw.SizedBox(height: 2);
      case QuestionType.fillBlankWithOptions:
        return pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Wrap(
            spacing: 12,
            children: [
              pw.Text('Word Bank: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              for (final w in q.wordBank) pw.Text(asciiSafe(w)),
            ],
          ),
        );
      case QuestionType.columnMatch:
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Column A',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  for (var i = 0; i < q.pairs.length; i++)
                    pw.Text('${i + 1}. ${asciiSafe(q.pairs[i].left)}'),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Column B',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  for (var i = 0; i < q.pairs.length; i++)
                    pw.Text(
                        '(${String.fromCharCode(97 + i)}) ${asciiSafe(q.pairs[i].right)}'),
                ],
              ),
            ),
          ],
        );
      case QuestionType.preschoolImage:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (q.imageBytes != null)
              pw.Container(
                height: 90,
                alignment: pw.Alignment.centerLeft,
                child: pw.Image(pw.MemoryImage(q.imageBytes!), height: 90),
              )
            else
              pw.Container(
                width: 120,
                height: 70,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text('[ picture ]'),
              ),
            if (q.options.isNotEmpty)
              pw.Row(
                children: [
                  for (final o in q.options)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 14),
                      child: pw.Text('( ) ${asciiSafe(o)}'),
                    ),
                ],
              )
            else
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4),
                width: 60,
                height: 30,
                decoration: pw.BoxDecoration(border: pw.Border.all()),
              ),
          ],
        );
    }
  }

  static pw.Widget _blankLines(int n) {
    return pw.Column(
      children: [
        for (var i = 0; i < n; i++)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            height: 0.6,
            color: PdfColors.grey600,
          ),
      ],
    );
  }

  static List<pw.Widget> _answerKey(TestPaper paper) {
    return [
      pw.SizedBox(height: 12),
      pw.Divider(thickness: 1),
      pw.Text('Answer Key',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      for (var i = 0; i < paper.questions.length; i++)
        pw.Text('Q${i + 1}. ${asciiSafe(answerOf(paper.questions[i]))}'),
    ];
  }
}
