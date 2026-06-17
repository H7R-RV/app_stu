import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document.dart';
import 'docx_export.dart';
import 'pdf_export.dart';

enum ExportFormat { pdfPreview, pdfShare, docx }

/// Generates and delivers the document in the requested format.
class ExportService {
  static Future<String?> run(ExportFormat format, TestDocument doc) async {
    final name = _safeName(doc.title);
    switch (format) {
      case ExportFormat.pdfPreview:
        final bytes = await PdfExporter.build(doc);
        await Printing.layoutPdf(name: '$name.pdf', onLayout: (_) async => bytes);
        return null;

      case ExportFormat.pdfShare:
        final bytes = await PdfExporter.build(doc);
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
        return 'PDF ready to share.';

      case ExportFormat.docx:
        final bytes = DocxExporter.build(doc);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name.docx');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(file.path)],
            subject: doc.title, text: doc.title);
        return 'Word document ready to share.';
    }
  }

  static String _safeName(String title) {
    final cleaned = title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return cleaned.isEmpty ? 'test_paper' : cleaned.replaceAll(' ', '_');
  }
}
