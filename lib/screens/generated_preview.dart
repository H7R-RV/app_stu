import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../export/generator_docx.dart';
import '../export/generator_pdf.dart';
import '../models/generator.dart';
import '../theme/app_theme.dart';

/// Shows the generated paper as the exact PDF, with PDF/Word/print actions.
class GeneratedPreview extends StatelessWidget {
  const GeneratedPreview({super.key, required this.paper});

  final GeneratedPaper paper;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Paper',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.appBarGradient),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Word (.docx)',
            icon: const Icon(Icons.description, color: Colors.white),
            onPressed: () => _shareWord(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => GeneratorPdf.build(paper),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }

  Future<void> _shareWord(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = GeneratorDocx.build(paper);
      final dir = await getTemporaryDirectory();
      final name = paper.config.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
      final file = File('${dir.path}/${name.isEmpty ? 'paper' : name}.docx');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], subject: paper.config.title);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Word export failed: $e')));
    }
  }
}
