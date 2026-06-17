import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../models/test_paper.dart';
import '../state/app_state.dart';
import '../widgets/question_editor.dart';
import '../widgets/question_view.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  bool _showAnswers = false;

  double _pageWidth(PaperSize size) {
    switch (size) {
      case PaperSize.a5:
        return 540;
      case PaperSize.legal:
      case PaperSize.letter:
        return 760;
      case PaperSize.a4:
        return 720;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final paper = state.paper;

    return Scaffold(
      body: Column(
        children: [
          _toolbar(context, state),
          Expanded(
            child: Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: _pageWidth(paper.size)),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8)
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: _pageContent(context, state),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addQuestionSheet(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Add question'),
      ),
    );
  }

  Widget _toolbar(BuildContext context, AppState state) {
    final paper = state.paper;
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.aspect_ratio, size: 20),
            const SizedBox(width: 6),
            DropdownButton<PaperSize>(
              value: paper.size,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in PaperSize.values)
                  DropdownMenuItem(
                    value: s,
                    child: Text('${s.label}  (${s.dimensionLabel})'),
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
            Tooltip(
              message: 'Show answer key',
              child: Row(
                children: [
                  const Text('Answers'),
                  Switch(
                    value: _showAnswers,
                    onChanged: (v) => setState(() => _showAnswers = v),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'clear') state.clearPaper();
                if (v == 'fill') state.quickFill();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'fill', child: Text('Quick fill sample')),
                PopupMenuItem(value: 'clear', child: Text('Clear all')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageContent(BuildContext context, AppState state) {
    final paper = state.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _paperHeader(paper),
        const SizedBox(height: 8),
        if (paper.questions.isEmpty)
          _emptyState(context, state)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: paper.questions.length,
            onReorder: state.reorder,
            itemBuilder: (context, i) {
              final q = paper.questions[i];
              return _QuestionTile(
                key: ValueKey(q.id),
                index: i,
                question: q,
                showAnswers: _showAnswers,
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuestionEditor(question: q),
                  ),
                ),
                onDuplicate: () => state.duplicate(q.id),
                onDelete: () => state.removeFromPaper(q.id),
              );
            },
          ),
      ],
    );
  }

  Widget _paperHeader(TestPaper paper) {
    return Column(
      children: [
        Text(
          paper.schoolName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          paper.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subject: ${paper.subject}'),
            Text('Class: ${paper.grade}'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Time: ${paper.timeAllowed}'),
            Text('Total Marks: ${paper.totalMarks}'),
          ],
        ),
        const SizedBox(height: 4),
        const Divider(thickness: 1.2),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Name: ____________________      Roll No: __________',
              style: TextStyle(color: Colors.grey.shade700)),
        ),
        if (paper.instructions.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Instructions: ${paper.instructions}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        const Divider(thickness: 1.2),
      ],
    );
  }

  Widget _emptyState(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.post_add, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Text('Your paper is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Add questions from the Question Bank tab, tap "Add question", '
            'or use Quick fill to generate a sample paper.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.bolt),
            label: const Text('Quick fill sample paper'),
            onPressed: () => state.quickFill(),
          ),
        ],
      ),
    );
  }

  void _addQuestionSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Add a new question',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              for (final t in QuestionType.values)
                ListTile(
                  leading: const Icon(Icons.add_box_outlined),
                  title: Text(t.label),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final q = state.addBlank(t);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuestionEditor(question: q),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One reorderable question row on the page with hover actions.
class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    super.key,
    required this.index,
    required this.question,
    required this.showAnswers,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final int index;
  final Question question;
  final bool showAnswers;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2, right: 6),
                  child: Icon(Icons.drag_indicator, color: Colors.grey),
                ),
              ),
              Expanded(
                child: QuestionView(
                  question: question,
                  number: index + 1,
                  showAnswers: showAnswers,
                ),
              ),
              Column(
                children: [
                  _iconBtn(Icons.edit, 'Edit', onEdit),
                  _iconBtn(Icons.copy, 'Duplicate', onDuplicate),
                  _iconBtn(Icons.delete_outline, 'Delete', onDelete,
                      color: Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback onTap,
      {Color? color}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      icon: Icon(icon, color: color),
      tooltip: tip,
      onPressed: onTap,
    );
  }
}
