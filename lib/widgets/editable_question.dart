import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../state/app_state.dart';
import 'inline_text_field.dart';
import 'page_layout.dart';

/// A question rendered directly on the page with every text inline-editable.
class EditableQuestion extends StatelessWidget {
  const EditableQuestion({
    super.key,
    required this.question,
    required this.number,
    required this.accent,
    required this.onSettings,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Question question;
  final int number;
  final Color accent;
  final VoidCallback onSettings;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final rev = context.select<AppState, int>((s) => s.revision);
    final q = question;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(6, 6, 4, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: accent,
                child: Text('$number',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InlineTextField(
                  key: ValueKey('q_${q.id}_$rev'),
                  initial: q.text,
                  hint: 'Type the question...',
                  style: const TextStyle(
                      fontSize: LayoutConst.bodyFont + 0.5,
                      fontWeight: FontWeight.w600),
                  maxLines: null,
                  onChanged: (v) => q.text = v,
                ),
              ),
              _MarksChip(question: q, accent: accent),
              _actions(state),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: _body(context, state, rev),
          ),
        ],
      ),
    );
  }

  Widget _actions(AppState state) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade500),
      padding: EdgeInsets.zero,
      splashRadius: 16,
      onSelected: (v) {
        if (v == 'settings') onSettings();
        if (v == 'duplicate') onDuplicate();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'settings',
            child: ListTile(
                leading: Icon(Icons.tune), title: Text('Advanced edit'))),
        PopupMenuItem(
            value: 'duplicate',
            child: ListTile(
                leading: Icon(Icons.copy), title: Text('Duplicate'))),
        PopupMenuItem(
            value: 'delete',
            child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete'))),
      ],
    );
  }

  Widget _body(BuildContext context, AppState state, int rev) {
    final q = question;
    switch (q.type) {
      case QuestionType.mcq:
        return _mcq(context, state, rev);
      case QuestionType.trueFalse:
        return _trueFalse(state);
      case QuestionType.shortQuestion:
        return const _BlankLines(lines: 2);
      case QuestionType.longQuestion:
        return const _BlankLines(lines: 5);
      case QuestionType.fillBlank:
        return Text('Write the answer in the blank.',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500));
      case QuestionType.fillBlankWithOptions:
        return _wordBank(state, rev);
      case QuestionType.columnMatch:
        return _match(state, rev);
      case QuestionType.preschoolImage:
        return _preschool(state, rev);
    }
  }

  // ---- MCQ with draggable options -----------------------------------------
  Widget _mcq(BuildContext context, AppState state, int rev) {
    final q = question;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: q.options.length,
      onReorder: (o, n) => state.reorderOptions(q, o, n),
      itemBuilder: (context, i) {
        return Padding(
          key: ValueKey('opt_${q.id}_${i}_$rev'),
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: i,
                child: Icon(Icons.drag_indicator,
                    size: 15, color: Colors.grey.shade400),
              ),
              GestureDetector(
                onTap: () {
                  q.correctOption = i;
                  state.touch();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: q.correctOption == i
                        ? accent
                        : Colors.grey.shade200,
                  ),
                  child: Text(
                    String.fromCharCode(65 + i),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: q.correctOption == i
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InlineTextField(
                  key: ValueKey('optf_${q.id}_${i}_$rev'),
                  initial: q.options[i],
                  hint: 'Option ${String.fromCharCode(65 + i)}',
                  style: const TextStyle(fontSize: LayoutConst.bodyFont),
                  onChanged: (v) => q.options[i] = v,
                ),
              ),
              InkWell(
                onTap: q.options.length <= 2
                    ? null
                    : () {
                        q.options.removeAt(i);
                        if (q.correctOption != null &&
                            q.correctOption! >= q.options.length) {
                          q.correctOption = q.options.length - 1;
                        }
                        state.updatePaperHeader();
                      },
                child: Icon(Icons.close,
                    size: 14, color: Colors.grey.shade400),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _trueFalse(AppState state) {
    final q = question;
    Widget opt(String label, bool value) {
      final selected = q.isTrue == value;
      return GestureDetector(
        onTap: () {
          q.isTrue = value;
          state.touch();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? accent : Colors.grey.shade300),
            color: selected ? accent.withOpacity(0.12) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 15, color: selected ? accent : Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Row(children: [opt('True', true), opt('False', false)]);
  }

  Widget _wordBank(AppState state, int rev) {
    final q = question;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Word Bank:',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold)),
          for (var i = 0; i < q.wordBank.length; i++)
            SizedBox(
              width: 90,
              child: InlineTextField(
                key: ValueKey('wb_${q.id}_${i}_$rev'),
                initial: q.wordBank[i],
                hint: 'word',
                style: const TextStyle(fontSize: 12),
                onChanged: (v) => q.wordBank[i] = v,
              ),
            ),
          InkWell(
            onTap: () {
              q.wordBank.add('');
              state.updatePaperHeader();
            },
            child: const Icon(Icons.add_circle_outline, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _match(AppState state, int rev) {
    final q = question;
    return Column(
      children: [
        for (var i = 0; i < q.pairs.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text('${i + 1}.',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Expanded(
                  child: InlineTextField(
                    key: ValueKey('ml_${q.id}_${i}_$rev'),
                    initial: q.pairs[i].left,
                    hint: 'Column A',
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) => q.pairs[i].left = v,
                  ),
                ),
                Icon(Icons.arrow_forward,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text('(${String.fromCharCode(97 + i)})',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                Expanded(
                  child: InlineTextField(
                    key: ValueKey('mr_${q.id}_${i}_$rev'),
                    initial: q.pairs[i].right,
                    hint: 'Column B',
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) => q.pairs[i].right = v,
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add pair', style: TextStyle(fontSize: 11)),
            onPressed: () {
              q.pairs.add(MatchPair(left: '', right: ''));
              state.updatePaperHeader();
            },
          ),
        ),
      ],
    );
  }

  Widget _preschool(AppState state, int rev) {
    final q = question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.imageBytes != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(q.imageBytes!, height: 90),
            ),
          )
        else
          SizedBox(
            width: 160,
            child: InlineTextField(
              key: ValueKey('emoji_${q.id}_$rev'),
              initial: q.emoji ?? '',
              hint: 'Add emoji e.g. 🍎🍎🍎 (or attach image in advanced)',
              style: const TextStyle(fontSize: 26),
              onChanged: (v) => q.emoji = v,
            ),
          ),
        if (q.options.isNotEmpty)
          Wrap(
            spacing: 10,
            children: [
              for (var i = 0; i < q.options.length; i++)
                SizedBox(
                  width: 90,
                  child: Row(
                    children: [
                      const Text('☐ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: InlineTextField(
                          key: ValueKey('pso_${q.id}_${i}_$rev'),
                          initial: q.options[i],
                          hint: 'choice',
                          style: const TextStyle(fontSize: 12),
                          onChanged: (v) => q.options[i] = v,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 70,
            height: 30,
            decoration: BoxDecoration(border: Border.all()),
          ),
      ],
    );
  }
}

class _MarksChip extends StatelessWidget {
  const _MarksChip({required this.question, required this.accent});
  final Question question;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return PopupMenuButton<String>(
      tooltip: 'Marks',
      onSelected: (v) {
        if (v == '+') question.marks++;
        if (v == '-' && question.marks > 1) question.marks--;
        state.touch();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: '+', child: Text('Increase marks')),
        PopupMenuItem(value: '-', child: Text('Decrease marks')),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${question.marks}',
            style: TextStyle(
                color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class _BlankLines extends StatelessWidget {
  const _BlankLines({required this.lines});
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lines; i++)
          Container(
            margin: const EdgeInsets.only(top: 16),
            height: 1,
            color: Colors.grey.shade300,
          ),
      ],
    );
  }
}
