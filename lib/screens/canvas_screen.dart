import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/page_size.dart';
import '../models/question.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/canvas_page.dart';
import '../widgets/inspector.dart';

class CanvasScreen extends StatelessWidget {
  const CanvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return Column(
          children: [
            const _Toolbar(),
            Expanded(
              child: wide ? _wideBody(context) : _narrowBody(context),
            ),
            const _PageStrip(),
          ],
        );
      },
    );
  }

  Widget _wideBody(BuildContext context) {
    final hasSel = context.select<AppState, bool>((s) => s.selected != null);
    return Row(
      children: [
        const Expanded(child: _PageArea()),
        if (hasSel)
          SizedBox(
            width: 320,
            child: Material(
              elevation: 4,
              child: SafeArea(
                child: Inspector(element: context.read<AppState>().selected!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _narrowBody(BuildContext context) {
    final sel = context.select<AppState, String?>((s) => s.selected?.id);
    return Stack(
      children: [
        const Positioned.fill(child: _PageArea()),
        if (sel != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              elevation: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Inspector(element: context.read<AppState>().selected!),
              ),
            ),
          ),
      ],
    );
  }
}

class _PageArea extends StatelessWidget {
  const _PageArea();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final size = state.doc.size;
    final page = state.page;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.deskGradient),
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, c) {
          final maxW = c.maxWidth - 40;
          final maxH = c.maxHeight - 40;
          final byHeight = maxH * (size.ptWidth / size.ptHeight);
          final displayWidth =
              math.min(math.min(maxW, byHeight), 720).toDouble();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CanvasPage(
                  page: page,
                  size: size,
                  displayWidth: displayWidth.clamp(220, 720),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Material(
      color: Colors.white,
      elevation: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _btn(Icons.title, 'Text', () => state.addText()),
            _btn(Icons.text_fields, 'Heading', state.addHeading),
            _btn(Icons.image, 'Image', () => _pickImage(context, state)),
            _btn(Icons.rectangle_outlined, 'Box', state.addRect),
            _btn(Icons.circle_outlined, 'Ellipse', state.addEllipse),
            _btn(Icons.horizontal_rule, 'Line', state.addLine),
            _btn(Icons.library_books, 'Library',
                () => _openLibrary(context, state)),
            const VerticalDivider(width: 16),
            const Icon(Icons.aspect_ratio, size: 18),
            DropdownButton<PaperSize>(
              value: state.doc.size,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in PaperSize.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) {
                if (v != null) state.setSize(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppTheme.seed),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, AppState state) async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final decoded = await ui.instantiateImageCodec(bytes);
    final frame = await decoded.getNextFrame();
    final aspect = frame.image.width / frame.image.height;
    state.addImage(bytes, aspect: aspect);
  }

  void _openLibrary(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _LibrarySheet(state: state),
    );
  }
}

class _LibrarySheet extends StatefulWidget {
  const _LibrarySheet({required this.state});
  final AppState state;

  @override
  State<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends State<_LibrarySheet> {
  String _subject = 'All';
  String _search = '';
  QuestionType? _type;

  @override
  Widget build(BuildContext context) {
    final results = widget.state
        .filteredBank(subject: _subject, type: _type, search: _search);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search the question library...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _chip('All', _subject == 'All', () => setState(() => _subject = 'All')),
                for (final s in widget.state.subjects)
                  _chip(s, _subject == s, () => setState(() => _subject = s)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: results.length,
              itemBuilder: (_, i) {
                final q = results[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.typeColor(q.type.index),
                    radius: 14,
                    child: Text(q.type.shortLabel.characters.first,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(q.text,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${q.type.label} • ${q.subject}'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () {
                    widget.state.addFromQuestion(q);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _PageStrip extends StatelessWidget {
  const _PageStrip();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pages = state.doc.pages.length;
    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pages,
                  itemBuilder: (_, i) {
                    final active = i == state.currentPage;
                    return GestureDetector(
                      onTap: () => state.setCurrentPage(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.seed.withOpacity(0.14)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: active ? AppTheme.seed : Colors.grey.shade300),
                        ),
                        child: Text('Page ${i + 1}',
                            style: TextStyle(
                                fontWeight:
                                    active ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  },
                ),
              ),
              if (pages > 1)
                IconButton(
                  tooltip: 'Delete this page',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => state.deletePage(state.currentPage),
                ),
              IconButton(
                tooltip: 'Add page',
                icon: const Icon(Icons.add_box, color: AppTheme.seed),
                onPressed: state.addPage,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
