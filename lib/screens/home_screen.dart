import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export/export_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'canvas_screen.dart';
import 'preview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canva Test Designer',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.appBarGradient),
        ),
        actions: [
          IconButton(
            tooltip: 'Print preview (exact)',
            icon: const Icon(Icons.visibility, color: Colors.white),
            onPressed: () {
              final state = context.read<AppState>();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PreviewScreen(doc: state.doc)));
            },
          ),
          PopupMenuButton<ExportFormat>(
            tooltip: 'Export',
            icon: const Icon(Icons.download, color: Colors.white),
            onSelected: (format) => _export(context, format),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ExportFormat.pdfPreview,
                child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Preview / Print PDF')),
              ),
              PopupMenuItem(
                value: ExportFormat.pdfShare,
                child: ListTile(
                    leading: Icon(Icons.ios_share),
                    title: Text('Save / Share PDF')),
              ),
              PopupMenuItem(
                value: ExportFormat.docx,
                child: ListTile(
                    leading: Icon(Icons.description),
                    title: Text('Save / Share Word (.docx)')),
              ),
            ],
          ),
        ],
      ),
      body: const CanvasScreen(),
    );
  }

  Future<void> _export(BuildContext context, ExportFormat format) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await ExportService.run(format, state.doc);
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
