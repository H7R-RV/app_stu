import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/doc_element.dart' show fontAsset;
import '../models/generator.dart';
import '../models/question.dart';
import 'font_loader.dart';
import 'text_utils.dart';

/// Renders a generated (blueprint-based) paper to a structured, paginated PDF.
class GeneratorPdf {
  static Future<Uint8List> build(GeneratedPaper paper) async {
    pw.Font? base;
    pw.Font? bold;
    try {
      base = await PdfFonts.load(fontAsset('Lato'));
      bold = await PdfFonts.load(fontAsset('Lato', bold: true));
    } catch (_) {}

    final theme = (base != null && bold != null)
        ? pw.ThemeData.withFont(base: base, bold: bold)
        : pw.ThemeData.base();

    final doc = pw.Document();
    final cfg = paper.config;

    for (final set in paper.sets) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9)),
          ),
          build: (ctx) {
            final widgets = <pw.Widget>[_header(cfg, set.label, paper.sets.length)];
            var qno = 1;
            for (final sec in set.sections) {
              widgets.add(_sectionHeader(sec));
              for (final q in sec.questions) {
                widgets.add(_question(q, qno, sec.spec.marksEach));
                qno++;
              }
            }
            if (cfg.answerKey) {
              widgets.addAll(_answerKey(set));
            }
            return widgets;
          },
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _header(GeneratorConfig c, String setLabel, int setCount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(asciiSafe(c.schoolName),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Center(
          child: pw.Text(asciiSafe(c.title),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
        if (setCount > 1)
          pw.Center(
            child: pw.Text('Set $setLabel',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subject: ${asciiSafe(c.subject)}'),
            pw.Text('Class: ${asciiSafe(c.grade)}'),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Time: ${asciiSafe(c.timeAllowed)}'),
            pw.Text('Total Marks: ${c.totalMarks}'),
          ],
        ),
        pw.Divider(thickness: 1),
        pw.Text('Name: ____________________     Roll No: __________'),
        if (c.instructions.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text('Instructions: ${asciiSafe(c.instructions)}',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
          ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  static pw.Widget _sectionHeader(GeneratedSection sec) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('${asciiSafe(sec.spec.name)} — ${asciiSafe(sec.spec.instruction)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('(${sec.spec.marksEach} each)',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _question(Question q, int number, int marks) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
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
              pw.Text('($marks)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, top: 2),
            child: _body(q),
          ),
        ],
      ),
    );
  }

  static pw.Widget _body(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        return pw.Wrap(
          spacing: 18,
          runSpacing: 2,
          children: [
            for (var i = 0; i < q.options.length; i++)
              pw.Text('(${String.fromCharCode(65 + i)}) ${asciiSafe(q.options[i])}'),
          ],
        );
      case QuestionType.trueFalse:
        return pw.Text('(   ) True        (   ) False');
      case QuestionType.shortQuestion:
        return _lines(2);
      case QuestionType.longQuestion:
        return _lines(5);
      case QuestionType.fillBlank:
        return pw.SizedBox(height: 2);
      case QuestionType.fillBlankWithOptions:
        return pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Text('Word Bank: ${q.wordBank.map(asciiSafe).join('   ')}'),
        );
      case QuestionType.columnMatch:
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < q.pairs.length; i++)
                    pw.Text('${i + 1}. ${asciiSafe(q.pairs[i].left)}'),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < q.pairs.length; i++)
                    pw.Text('(${String.fromCharCode(97 + i)}) ${asciiSafe(q.pairs[i].right)}'),
                ],
              ),
            ),
          ],
        );
      case QuestionType.preschoolImage:
        return pw.Container(
          width: 110,
          height: 50,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          alignment: pw.Alignment.center,
          child: pw.Text('[ picture ]'),
        );
    }
  }

  static pw.Widget _lines(int n) {
    return pw.Column(children: [
      for (var i = 0; i < n; i++)
        pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            height: 0.6,
            color: PdfColors.grey600),
    ]);
  }

  static List<pw.Widget> _answerKey(GeneratedSet set) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 10),
      pw.Divider(thickness: 1),
      pw.Text('Answer Key (Set ${set.label})',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
    ];
    var n = 1;
    for (final sec in set.sections) {
      for (final q in sec.questions) {
        widgets.add(pw.Text('Q$n. ${asciiSafe(answerOf(q))}'));
        n++;
      }
    }
    return widgets;
  }
}
