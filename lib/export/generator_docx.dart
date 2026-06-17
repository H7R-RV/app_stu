import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/generator.dart';
import '../models/question.dart';
import 'text_utils.dart';

/// Renders a generated paper to a Microsoft Word (.docx) file.
class GeneratorDocx {
  static Uint8List build(GeneratedPaper paper) {
    final b = StringBuffer();
    final cfg = paper.config;

    for (var s = 0; s < paper.sets.length; s++) {
      final set = paper.sets[s];
      if (s > 0) {
        b.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }
      b.write(_p(cfg.schoolName, bold: true, size: 32, align: 'center'));
      b.write(_p(cfg.title, bold: true, size: 26, align: 'center'));
      if (paper.sets.length > 1) {
        b.write(_p('Set ${set.label}', bold: true, size: 22, align: 'center'));
      }
      b.write(_p('Subject: ${cfg.subject}\t\tClass: ${cfg.grade}', size: 22));
      b.write(_p('Time: ${cfg.timeAllowed}\t\tTotal Marks: ${cfg.totalMarks}',
          size: 22));
      b.write(_rule());
      b.write(_p('Name: ____________________     Roll No: __________', size: 22));
      if (cfg.instructions.trim().isNotEmpty) {
        b.write(_p('Instructions: ${cfg.instructions}', italic: true, size: 20));
      }
      b.write(_rule());

      var n = 1;
      for (final sec in set.sections) {
        b.write(_p('${sec.spec.name} — ${sec.spec.instruction}   (${sec.spec.marksEach} each)',
            bold: true, size: 24, spacingBefore: 120));
        for (final q in sec.questions) {
          b.write(_p('Q$n. ${q.text}   (${sec.spec.marksEach})',
              bold: true, size: 22));
          b.write(_body(q));
          n++;
        }
      }

      if (cfg.answerKey) {
        b.write(_rule());
        b.write(_p('Answer Key (Set ${set.label})', bold: true, size: 24));
        var k = 1;
        for (final sec in set.sections) {
          for (final q in sec.questions) {
            b.write(_p('Q$k. ${answerOf(q)}', size: 22));
            k++;
          }
        }
      }
    }

    return _zip(b.toString());
  }

  static String _body(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        final opts = [
          for (var i = 0; i < q.options.length; i++)
            '(${String.fromCharCode(65 + i)}) ${q.options[i]}'
        ].join('     ');
        return _p(opts, size: 22, indent: 360);
      case QuestionType.trueFalse:
        return _p('(   ) True        (   ) False', size: 22, indent: 360);
      case QuestionType.shortQuestion:
        return _line() + _line();
      case QuestionType.longQuestion:
        return _line() + _line() + _line() + _line() + _line();
      case QuestionType.fillBlankWithOptions:
        return _p('Word Bank: ${q.wordBank.join('   ')}',
            bold: true, size: 22, indent: 360);
      case QuestionType.columnMatch:
        final sb = StringBuffer();
        for (var i = 0; i < q.pairs.length; i++) {
          sb.write(_p(
              '${i + 1}. ${q.pairs[i].left}\t\t(${String.fromCharCode(97 + i)}) ${q.pairs[i].right}',
              size: 22, indent: 360));
        }
        return sb.toString();
      case QuestionType.fillBlank:
      case QuestionType.preschoolImage:
        return '';
    }
  }

  static String _p(String text,
      {bool bold = false,
      bool italic = false,
      int size = 22,
      String align = 'left',
      int indent = 0,
      int spacingBefore = 0}) {
    final runs = StringBuffer();
    final parts = text.split('\t');
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) runs.write('<w:r><w:tab/></w:r>');
      runs.write('<w:r><w:rPr>'
          '${bold ? '<w:b/>' : ''}${italic ? '<w:i/>' : ''}'
          '<w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr>'
          '<w:t xml:space="preserve">${xmlEscape(parts[i])}</w:t></w:r>');
    }
    final pPr = StringBuffer('<w:pPr>');
    if (align != 'left') pPr.write('<w:jc w:val="$align"/>');
    if (indent > 0) pPr.write('<w:ind w:left="$indent"/>');
    if (spacingBefore > 0) pPr.write('<w:spacing w:before="$spacingBefore"/>');
    pPr.write('</w:pPr>');
    return '<w:p>$pPr$runs</w:p>';
  }

  static String _line() =>
      '<w:p><w:pPr><w:spacing w:before="160"/>'
      '<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="999999"/></w:pBdr>'
      '</w:pPr></w:p>';

  static String _rule() =>
      '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="12" w:space="1" w:color="000000"/></w:pBdr></w:pPr></w:p>';

  static Uint8List _zip(String body) {
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>');
    add('_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>');
    add('word/document.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>$body'
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr>'
        '</w:body></w:document>');

    final out = ZipEncoder().encode(archive) ?? <int>[];
    return Uint8List.fromList(out);
  }
}
