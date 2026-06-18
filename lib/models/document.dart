import 'dart:convert';

import 'doc_element.dart';
import 'page_size.dart';

/// Header band shown on the FIRST page only.
class HeaderConfig {
  bool enabled = false;
  String school = 'City Public School';
  String title = 'First Term Examination';
  String subject = 'Subject: __________';
  String meta = 'Class: ______    Date: __________    Marks: ______';
  bool studentGrid = true;
  String? logoB64;

  Map<String, dynamic> toJson() => {
        'en': enabled,
        's': school,
        't': title,
        'sub': subject,
        'm': meta,
        'sg': studentGrid,
        'logo': logoB64,
      };

  static HeaderConfig fromJson(Map<String, dynamic> j) => HeaderConfig()
    ..enabled = j['en'] as bool? ?? false
    ..school = j['s'] as String? ?? ''
    ..title = j['t'] as String? ?? ''
    ..subject = j['sub'] as String? ?? ''
    ..meta = j['m'] as String? ?? ''
    ..studentGrid = j['sg'] as bool? ?? true
    ..logoB64 = j['logo'] as String?;
}

/// Footer replicated on ALL pages.
class FooterConfig {
  bool enabled = false;
  String text = 'Best of luck!';
  bool pageNumber = true;

  Map<String, dynamic> toJson() =>
      {'en': enabled, 't': text, 'pn': pageNumber};

  static FooterConfig fromJson(Map<String, dynamic> j) => FooterConfig()
    ..enabled = j['en'] as bool? ?? false
    ..text = j['t'] as String? ?? ''
    ..pageNumber = j['pn'] as bool? ?? true;
}

/// One page holds elements (list order == z-order) plus freehand strokes.
class DocPage {
  final List<DocElement> elements = [];
  final List<Stroke> strokes = [];

  Map<String, dynamic> toJson() => {
        'el': [for (final e in elements) e.toJson()],
        'st': [for (final s in strokes) s.toJson()],
      };

  static DocPage fromJson(Map<String, dynamic> j) {
    final p = DocPage();
    for (final e in (j['el'] as List? ?? [])) {
      p.elements.add(DocElement.fromJson(e as Map<String, dynamic>));
    }
    for (final s in (j['st'] as List? ?? [])) {
      p.strokes.add(Stroke.fromJson(s as Map<String, dynamic>));
    }
    return p;
  }
}

/// The whole design document.
class TestDocument {
  PaperSize size = PaperSize.a4;
  String title = 'My Test Paper';

  // Independent margins in PDF points.
  double marginTop = 36;
  double marginRight = 36;
  double marginBottom = 36;
  double marginLeft = 36;

  final HeaderConfig header = HeaderConfig();
  final FooterConfig footer = FooterConfig();
  final List<DocPage> pages = [DocPage()];

  Map<String, dynamic> toJson() => {
        'size': size.index,
        'title': title,
        'mt': marginTop,
        'mr': marginRight,
        'mb': marginBottom,
        'ml': marginLeft,
        'header': header.toJson(),
        'footer': footer.toJson(),
        'pages': [for (final p in pages) p.toJson()],
      };

  String encode() => jsonEncode(toJson());

  void loadFrom(Map<String, dynamic> j) {
    size = PaperSize.values[j['size'] as int? ?? 0];
    title = j['title'] as String? ?? 'My Test Paper';
    marginTop = (j['mt'] as num?)?.toDouble() ?? 36;
    marginRight = (j['mr'] as num?)?.toDouble() ?? 36;
    marginBottom = (j['mb'] as num?)?.toDouble() ?? 36;
    marginLeft = (j['ml'] as num?)?.toDouble() ?? 36;
    final h = HeaderConfig.fromJson(
        (j['header'] as Map?)?.cast<String, dynamic>() ?? {});
    header
      ..enabled = h.enabled
      ..school = h.school
      ..title = h.title
      ..subject = h.subject
      ..meta = h.meta
      ..studentGrid = h.studentGrid
      ..logoB64 = h.logoB64;
    final f = FooterConfig.fromJson(
        (j['footer'] as Map?)?.cast<String, dynamic>() ?? {});
    footer
      ..enabled = f.enabled
      ..text = f.text
      ..pageNumber = f.pageNumber;
    pages
      ..clear()
      ..addAll([
        for (final p in (j['pages'] as List? ?? []))
          DocPage.fromJson(p as Map<String, dynamic>)
      ]);
    if (pages.isEmpty) pages.add(DocPage());
  }

  static TestDocument decode(String s) {
    final doc = TestDocument();
    doc.loadFrom(jsonDecode(s) as Map<String, dynamic>);
    return doc;
  }
}
