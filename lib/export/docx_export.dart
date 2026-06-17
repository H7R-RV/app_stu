import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/question.dart';
import '../models/test_paper.dart';
import 'text_utils.dart';

/// Builds the test paper as a Microsoft Word (.docx) file.
///
/// A .docx is a ZIP package of OOXML parts; we assemble the minimal set of
/// parts needed for a valid, Word-openable document (with embedded images).
class DocxExporter {
  static Uint8List build(TestPaper paper) {
    final body = StringBuffer();
    final media = <_Media>[];
    final rels = StringBuffer();
    var relId = 1;
    var drawingId = 1;

    String addImage(Uint8List bytes) {
      final name = 'image$relId.png';
      final rid = 'rId$relId';
      media.add(_Media(name, bytes));
      rels.write(
          '<Relationship Id="$rid" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/$name"/>');
      relId++;
      return rid;
    }

    // ---- Header ----
    final c = paper.header;
    if (c.showSchool) {
      body.write(_para(paper.schoolName, bold: true, size: 32, align: 'center'));
    }
    if (c.showTitle) {
      body.write(_para(paper.title, bold: true, size: 26, align: 'center'));
    }
    final meta1 = [
      if (c.showSubject) 'Subject: ${paper.subject}',
      if (c.showClass) 'Class: ${paper.grade}',
    ];
    final meta2 = [
      if (c.showTime) 'Time: ${paper.timeAllowed}',
      if (c.showMarks) 'Total Marks: ${paper.totalMarks}',
    ];
    if (meta1.isNotEmpty) body.write(_para(meta1.join('\t\t'), size: 22));
    if (meta2.isNotEmpty) body.write(_para(meta2.join('\t\t'), size: 22));
    body.write(_rule());
    final student = [
      if (c.showName) 'Name: ____________________',
      if (c.showRoll) 'Roll No: __________',
      if (c.showDate) 'Date: ${c.date.isEmpty ? '__________' : c.date}',
    ];
    if (student.isNotEmpty) body.write(_para(student.join('     '), size: 22));
    if (c.showInstructions && paper.instructions.trim().isNotEmpty) {
      body.write(_para('Instructions: ${paper.instructions}',
          italic: true, size: 20));
    }
    body.write(_rule());

    // ---- Questions ----
    for (var i = 0; i < paper.questions.length; i++) {
      final q = paper.questions[i];
      body.write(_para('Q${i + 1}. ${q.text}   (${q.marks})',
          bold: true, size: 22, spacingBefore: 120));
      body.write(_questionBody(q, addImage, () => drawingId++));
    }

    // ---- Answer key ----
    if (paper.showAnswerKey) {
      body.write(_rule());
      body.write(_para('Answer Key', bold: true, size: 26));
      for (var i = 0; i < paper.questions.length; i++) {
        body.write(_para('Q${i + 1}. ${answerOf(paper.questions[i])}',
            size: 22));
      }
    }

    return _zip(paper, body.toString(), rels.toString(), media);
  }

  static String _questionBody(
      Question q, String Function(Uint8List) addImage, int Function() nextId) {
    final b = StringBuffer();
    switch (q.type) {
      case QuestionType.mcq:
        String opt(int i) =>
            '(${String.fromCharCode(65 + i)})  ${q.options[i]}';
        if (q.mcqLayout == McqLayout.row) {
          b.write(_para(
              [for (var i = 0; i < q.options.length; i++) opt(i)].join('     '),
              size: 22, indent: 360));
        } else if (q.mcqLayout == McqLayout.twoColumn) {
          for (var i = 0; i < q.options.length; i += 2) {
            final right = i + 1 < q.options.length ? '\t\t${opt(i + 1)}' : '';
            b.write(_para('${opt(i)}$right', size: 22, indent: 360));
          }
        } else {
          for (var i = 0; i < q.options.length; i++) {
            b.write(_para(opt(i), size: 22, indent: 360));
          }
        }
        break;
      case QuestionType.trueFalse:
        b.write(_para('(  ) True            (  ) False',
            size: 22, indent: 360));
        break;
      case QuestionType.shortQuestion:
        for (var i = 0; i < 2; i++) {
          b.write(_blankLine());
        }
        break;
      case QuestionType.longQuestion:
        for (var i = 0; i < 5; i++) {
          b.write(_blankLine());
        }
        break;
      case QuestionType.fillBlank:
        break;
      case QuestionType.fillBlankWithOptions:
        b.write(_para('Word Bank:  ${q.wordBank.join('    ')}',
            bold: true, size: 22, indent: 360));
        break;
      case QuestionType.columnMatch:
        b.write(_para('Column A\t\t\tColumn B', bold: true, size: 22));
        for (var i = 0; i < q.pairs.length; i++) {
          final right = i < q.pairs.length ? q.pairs[i].right : '';
          b.write(_para(
              '${i + 1}. ${q.pairs[i].left}\t\t\t(${String.fromCharCode(97 + i)}) $right',
              size: 22, indent: 360));
        }
        break;
      case QuestionType.preschoolImage:
        if ((q.emoji ?? '').isNotEmpty && q.imageBytes == null) {
          b.write(_para(q.emoji!, size: 48, indent: 360));
        }
        if (q.imageBytes != null) {
          final rid = addImage(q.imageBytes!);
          b.write(_imagePara(rid, nextId()));
        }
        if (q.options.isNotEmpty) {
          b.write(_para(q.options.map((o) => '( ) $o').join('     '),
              size: 22, indent: 360));
        } else {
          b.write(_para('____________________', size: 22, indent: 360));
        }
        break;
    }
    return b.toString();
  }

  // ---- Paragraph builders --------------------------------------------------

  static String _para(
    String text, {
    bool bold = false,
    bool italic = false,
    int size = 22,
    String align = 'left',
    int indent = 0,
    int spacingBefore = 0,
  }) {
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
    return '<w:p>${pPr.toString()}${runs.toString()}</w:p>';
  }

  /// A paragraph with a bottom border, used as a writing line.
  static String _blankLine() {
    return '<w:p><w:pPr><w:spacing w:before="160"/>'
        '<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="999999"/></w:pBdr>'
        '</w:pPr></w:p>';
  }

  /// A full-width bottom-bordered separator paragraph.
  static String _rule() {
    return '<w:p><w:pPr>'
        '<w:pBdr><w:bottom w:val="single" w:sz="12" w:space="1" w:color="000000"/></w:pBdr>'
        '</w:pPr></w:p>';
  }

  /// Inline image run (about 1.8in x 1.2in).
  static String _imagePara(String rid, int id) {
    const cx = 1828800;
    const cy = 1219200;
    return '<w:p><w:r><w:drawing>'
        '<wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="$cx" cy="$cy"/>'
        '<wp:docPr id="$id" name="Picture $id"/>'
        '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:nvPicPr><pic:cNvPr id="$id" name="Picture $id"/><pic:cNvPicPr/></pic:nvPicPr>'
        '<pic:blipFill><a:blip r:embed="$rid"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
        '</pic:pic></a:graphicData></a:graphic>'
        '</wp:inline></w:drawing></w:r></w:p>';
  }

  // ---- ZIP packaging -------------------------------------------------------

  static Uint8List _zip(
      TestPaper paper, String body, String imageRels, List<_Media> media) {
    final archive = Archive();

    void addFile(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    addFile('[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Default Extension="png" ContentType="image/png"/>'
        '<Default Extension="jpg" ContentType="image/jpeg"/>'
        '<Default Extension="jpeg" ContentType="image/jpeg"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>');

    addFile('_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>');

    addFile('word/_rels/document.xml.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '$imageRels'
        '</Relationships>');

    final sectPr = '<w:sectPr>'
        '<w:pgSz w:w="${paper.size.docxWidthTwips}" w:h="${paper.size.docxHeightTwips}"/>'
        '<w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="0" w:footer="0" w:gutter="0"/>'
        '</w:sectPr>';

    addFile('word/document.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
        'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<w:body>$body$sectPr</w:body></w:document>');

    for (final m in media) {
      archive.addFile(ArchiveFile('word/media/${m.name}', m.bytes.length, m.bytes));
    }

    final out = ZipEncoder().encode(archive) ?? <int>[];
    return Uint8List.fromList(out);
  }
}

class _Media {
  _Media(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}
