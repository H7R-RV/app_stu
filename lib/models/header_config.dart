import 'dart:typed_data';

/// Visual style for the paper's header band.
enum HeaderTemplate { classic, modern, compact, formal }

extension HeaderTemplateInfo on HeaderTemplate {
  String get label {
    switch (this) {
      case HeaderTemplate.classic:
        return 'Classic';
      case HeaderTemplate.modern:
        return 'Modern';
      case HeaderTemplate.compact:
        return 'Compact';
      case HeaderTemplate.formal:
        return 'Formal';
    }
  }
}

/// All the toggles and style choices for the editable header.
class HeaderConfig {
  HeaderTemplate template = HeaderTemplate.modern;

  bool showLogo = true;
  bool showSchool = true;
  bool showTitle = true;
  bool showSubject = true;
  bool showClass = true;
  bool showTime = true;
  bool showMarks = true;
  bool showName = true;
  bool showRoll = true;
  bool showDate = true;
  bool showInstructions = true;

  bool centered = true;

  /// Optional logo image; falls back to [logoEmoji] when null.
  Uint8List? logoBytes;
  String logoEmoji = '🏫';

  String date = '';
}
