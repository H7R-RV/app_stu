import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export/export_service.dart';
import '../state/app_state.dart';
import 'builder_screen.dart';
import 'paper_settings_screen.dart';
import 'question_bank_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 1; // start on the builder

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final count = state.paper.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Generator'),
        actions: [
          IconButton(
            tooltip: 'Paper settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaperSettingsScreen()),
            ),
          ),
          PopupMenuButton<ExportFormat>(
            tooltip: 'Export',
            icon: const Icon(Icons.download),
            onSelected: (format) => _export(context, format),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ExportFormat.pdfPreview,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Preview / Print PDF'),
                ),
              ),
              PopupMenuItem(
                value: ExportFormat.pdfShare,
                child: ListTile(
                  leading: Icon(Icons.ios_share),
                  title: Text('Save / Share PDF'),
                ),
              ),
              PopupMenuItem(
                value: ExportFormat.docx,
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Save / Share Word (.docx)'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          QuestionBankScreen(),
          BuilderScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Question Bank',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: const Icon(Icons.assignment),
            label: 'Build Paper',
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, ExportFormat format) async {
    final state = context.read<AppState>();
    if (state.paper.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some questions to the paper first.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await ExportService.run(format, state.paper);
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
