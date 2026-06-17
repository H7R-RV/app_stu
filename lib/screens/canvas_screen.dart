import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/doc_element.dart';
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
    final editing = context.select<AppState, bool>((s) => s.editingId != null);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return Column(
          children: [
            editing ? const _EditBar() : const _Toolbar(),
            Expanded(
              child: wide ? _wideBody(context, editing) : _narrowBody(context, editing),
            ),
            if (!editing) const _PageStrip(),
          ],
        );
      },
    );
  }

  Widget _wideBody(BuildContext context, bool editing) {
    final showInspector =
        context.select<AppState, bool>((s) => s.selected != null) && !editing;
    return Row(
      children: [
        const Expanded(child: _PageArea()),
        if (showInspector)
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

  Widget _narrowBody(BuildContext context, bool editing) {
    final sel = context.select<AppState, String?>((s) => s.selected?.id);
    final showInspector = sel != null && !editing;
    return Stack(
      children: [
        const Positioned.fill(child: _PageArea()),
        if (showInspector)
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              elevation: 8,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 290),
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
            _btn(Icons.category, 'Shapes', () => _openShapes(context, state)),
            _btn(Icons.dashboard_customize, 'Designs',
                () => _openTemplates(context, state)),
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

  void _openShapes(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        Widget tile(IconData icon, String label, VoidCallback onTap) {
          return InkWell(
            onTap: () {
              onTap();
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: AppTheme.seed),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: [
                tile(Icons.rectangle_outlined, 'Rectangle', state.addRect),
                tile(Icons.circle_outlined, 'Ellipse', state.addEllipse),
                tile(Icons.horizontal_rule, 'Line', state.addLine),
                tile(Icons.change_history, 'Triangle',
                    () => state.addPolygon(ShapeKind.triangle)),
                tile(Icons.diamond_outlined, 'Diamond',
                    () => state.addPolygon(ShapeKind.diamond)),
                tile(Icons.pentagon_outlined, 'Pentagon',
                    () => state.addPolygon(ShapeKind.pentagon)),
                tile(Icons.hexagon_outlined, 'Hexagon',
                    () => state.addPolygon(ShapeKind.hexagon)),
                tile(Icons.star_border, 'Star',
                    () => state.addPolygon(ShapeKind.star)),
                tile(Icons.arrow_right_alt, 'Arrow',
                    () => state.addPolygon(ShapeKind.arrow)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openTemplates(BuildContext context, AppState state) {
    final items = <List<dynamic>>[
      [Icons.school, 'Exam header', 'header'],
      ['section', 'Section bar', 'section'],
      [Icons.checklist, 'MCQ block', 'mcq'],
      [Icons.rule, 'True / False', 'truefalse'],
      [Icons.notes, 'Answer lines', 'answer'],
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Ready-made designs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final it in items)
              ListTile(
                leading: Icon(it[0] is IconData ? it[0] as IconData : Icons.view_agenda,
                    color: AppTheme.seed),
                title: Text(it[1] as String),
                onTap: () {
                  state.insertTemplate(it[2] as String);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
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

/// Compact formatting bar shown while editing a text element, so the inspector
/// and keyboard don't cover the page.
class _EditBar extends StatelessWidget {
  const _EditBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final e = state.selected;
    return Material(
      color: AppTheme.seed,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => state.stopEditing(),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Done',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (e != null)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _w(Icons.format_bold, e.bold, () {
                          e.bold = !e.bold;
                          state.touch();
                        }),
                        _w(Icons.format_italic, e.italic, () {
                          e.italic = !e.italic;
                          state.touch();
                        }),
                        _w(Icons.format_underlined, e.underline, () {
                          e.underline = !e.underline;
                          state.touch();
                        }),
                        _plain(Icons.remove, () {
                          e.fontSize = math.max(6, e.fontSize - 2);
                          state.touch();
                        }),
                        Text('${e.fontSize.round()}',
                            style: const TextStyle(color: Colors.white)),
                        _plain(Icons.add, () {
                          e.fontSize = math.min(120, e.fontSize + 2);
                          state.touch();
                        }),
                        const SizedBox(width: 6),
                        for (final c in const [
                          0xFF111111,
                          0xFFEF4444,
                          0xFF0EA5E9,
                          0xFF22C55E,
                          0xFFF59E0B,
                          0xFF8B5CF6,
                          0xFFFFFFFF,
                        ])
                          GestureDetector(
                            onTap: () {
                              e.color = c;
                              state.touch();
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white70),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _w(IconData icon, bool on, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: on ? Colors.amberAccent : Colors.white, size: 20),
    );
  }

  Widget _plain(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
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

  @override
  Widget build(BuildContext context) {
    final results =
        widget.state.filteredBank(subject: _subject, search: _search);
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
                _chip('All', _subject == 'All',
                    () => setState(() => _subject = 'All')),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title:
                      Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                              color: active
                                  ? AppTheme.seed
                                  : Colors.grey.shade300),
                        ),
                        child: Text('Page ${i + 1}',
                            style: TextStyle(
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
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
