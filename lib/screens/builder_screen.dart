import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../models/test_paper.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/page_canvas.dart';
import '../widgets/question_editor.dart';
import '../widgets/question_palette.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  bool _tilt3d = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openEditor(Question q) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuestionEditor(question: q)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Row(
            children: [
              SizedBox(
                width: 320,
                child: Material(
                  elevation: 2,
                  child: const QuestionPalette(),
                ),
              ),
              Expanded(child: _canvasArea(wide: true)),
            ],
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          drawer: const Drawer(child: SafeArea(child: QuestionPalette())),
          body: _canvasArea(wide: false),
        );
      },
    );
  }

  Widget _canvasArea({required bool wide}) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.deskGradient),
      child: Column(
        children: [
          _toolbar(wide: wide),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final pageWidth =
                    math.min(c.maxWidth - 40, 820).toDouble().clamp(280.0, 820.0);
                return _PaperScroll(pageWidth: pageWidth, tilt: _tilt3d, onEdit: _openEditor);
              },
            ),
          ),
        ],
      ),
      // ignore: deprecated_member_use
    );
  }

  Widget _toolbar({required bool wide}) {
    final state = context.watch<AppState>();
    final paper = state.paper;
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            if (!wide)
              IconButton(
                tooltip: 'Question library',
                icon: const Icon(Icons.library_books),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            Icon(Icons.aspect_ratio, size: 18, color: AppTheme.seed),
            const SizedBox(width: 4),
            DropdownButton<PaperSize>(
              value: paper.size,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final s in PaperSize.values)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) {
                  paper.size = v;
                  state.updatePaperHeader();
                }
              },
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Page margins & padding',
              icon: const Icon(Icons.space_dashboard_outlined),
              onPressed: () => _openLayoutSheet(paper),
            ),
            IconButton(
              tooltip: '3D view',
              icon: Icon(_tilt3d ? Icons.threed_rotation : Icons.crop_portrait),
              color: _tilt3d ? AppTheme.accent : null,
              onPressed: () => setState(() => _tilt3d = !_tilt3d),
            ),
            IconButton(
              tooltip: 'Re-flow pages',
              icon: const Icon(Icons.refresh),
              onPressed: state.reflow,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'fill') state.quickFill();
                if (v == 'clear') state.clearPaper();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'fill',
                    child: ListTile(
                        leading: Icon(Icons.bolt),
                        title: Text('Quick fill sample'))),
                PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                        leading: Icon(Icons.delete_sweep),
                        title: Text('Clear all'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openLayoutSheet(TestPaper paper) {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Page margins & padding',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Margin: ${paper.marginMm.round()} mm'),
              Slider(
                min: 5,
                max: 40,
                value: paper.marginMm,
                label: '${paper.marginMm.round()} mm',
                onChanged: (v) {
                  setSheet(() => paper.marginMm = v);
                  state.updatePaperHeader();
                },
              ),
              Text('Inner padding: ${paper.paddingMm.round()} mm'),
              Slider(
                min: 0,
                max: 20,
                value: paper.paddingMm,
                label: '${paper.paddingMm.round()} mm',
                onChanged: (v) {
                  setSheet(() => paper.paddingMm = v);
                  state.updatePaperHeader();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The scrolling stack of pages, with an optional subtle 3D tilt and a FAB
/// to add a new blank question of any type.
class _PaperScroll extends StatelessWidget {
  const _PaperScroll({
    required this.pageWidth,
    required this.tilt,
    required this.onEdit,
  });

  final double pageWidth;
  final bool tilt;
  final void Function(Question) onEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final empty = state.paper.questions.isEmpty;

    Widget canvas = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(
          width: pageWidth,
          child: PageCanvas(pageWidth: pageWidth, onAdvancedEdit: onEdit),
        ),
      ),
    );

    if (tilt) {
      canvas = Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0008)
          ..rotateX(0.06),
        child: canvas,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(child: canvas),
        ),
        if (empty)
          Positioned.fill(child: IgnorePointer(child: _emptyHint())),
        Positioned(
          right: 16,
          bottom: 16,
          child: _AddFab(onEdit: onEdit),
        ),
      ],
    );
  }

  Widget _emptyHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, color: Colors.grey.shade600, size: 40),
          const SizedBox(height: 8),
          Text('Drag questions from the library,\nor tap + to add one',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700)),
        ],
      ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn().moveY(
          begin: 0, end: -6, duration: 1200.ms, curve: Curves.easeInOut),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onEdit});
  final void Function(Question) onEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.fabGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.pageShadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _sheet(context, state),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 6),
                Text('Add question',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('New question',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            for (final t in QuestionType.values)
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.typeColor(t.index),
                  child: Text(t.shortLabel.characters.first,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(t.label),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final q = state.addBlank(t);
                  onEdit(q);
                },
              ),
          ],
        ),
      ),
    );
  }
}
