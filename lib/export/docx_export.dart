import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart' show TextAlign;

import '../models/doc_element.dart';
import '../models/document.dart';
import '../models/page_size.dart';
import 'text_utils.dart';

/// Best-effort Microsoft Word (.docx) export of the canvas document.
///
/// Word is not an absolute-positioning format, so elements are emitted in
/// reading order (top-to-bottom, left-to-right per page) as styled paragraphs;
/// images are embedded. The PDF export is the pixel-accurate one.
class DocxExporter {
  static Uint8List build(TestDocument doc) {
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

    for (var p = 0; p < doc.pages.length; p++) {
      final elements = [...doc.pages[p].elements]
        ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
      for (final e in elements) {
        switch (e.type) {
          case ElementType.text:
            for (final line in e.text.split('\n')) {
              body.write(_textPara(e, line));
            }
            break;
          case ElementType.image:
            if (e.imageBytes != null) {
              body.write(_imagePara(addImage(e.imageBytes!), drawingId++,
                  e.w, e.h));
            }
            break;
          case ElementType.rect:
          case ElementType.ellipse:
          case ElementType.line:
            break; // shapes are not represented in the Word flow
        }
      }
      if (p < doc.pages.length - 1) {
        body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }
    }

    return _zip(doc, body.toString(), rels.toString(), media);
  }

  static String _textPara(DocElement e, String text) {
    final hex = _hex(e.color);
    final size = (e.fontSize * 2).round(); // half-points
    final jc = e.align == TextAlign.center
        ? 'center'
        : (e.align == TextAlign.right ? 'right' : 'left');
    return '<w:p><w:pPr><w:jc w:val="$jc"/></w:pPr>'
        '<w:r><w:rPr>'
        '<w:rFonts w:ascii="${xmlEscape(e.fontFamily)}" w:hAnsi="${xmlEscape(e.fontFamily)}"/>'
        '${e.bold ? '<w:b/>' : ''}${e.italic ? '<w:i/>' : ''}'
        '${e.underline ? '<w:u w:val="single"/>' : ''}'
        '<w:color w:val="$hex"/><w:sz w:val="$size"/><w:szCs w:val="$size"/>'
        '</w:rPr><w:t xml:space="preserve">${xmlEscape(text)}</w:t></w:r></w:p>';
  }

  static String _imagePara(String rid, int id, double wPt, double hPt) {
    final cx = (wPt * 12700).round(); // pt -> EMU
    final cy = (hPt * 12700).round();
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

  static String _hex(int argb) {
    final r = ((argb >> 16) & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((argb >> 8) & 0xff).toRadixString(16).padLeft(2, '0');
    final b = (argb & 0xff).toRadixString(16).padLeft(2, '0');
    return '$r$g$b';
  }

  static Uint8List _zip(
      TestDocument doc, String body, String imageRels, List<_Media> media) {
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
        '<w:pgSz w:w="${doc.size.docxWidthTwips}" w:h="${doc.size.docxHeightTwips}"/>'
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
      archive.addFile(
          ArchiveFile('word/media/${m.name}', m.bytes.length, m.bytes));
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
