import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../export/pdf_export.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';

/// Shows the document exactly as it will print, by rendering the real PDF.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.doc});

  final TestDocument doc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Preview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.appBarGradient),
        ),
      ),
      body: PdfPreview(
        build: (format) => PdfExporter.build(doc),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
