import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../state/app_state.dart';
import 'inline_text_field.dart';
import 'page_layout.dart';

/// Document text colour and base style so the page reads like printed paper.
const Color _ink = Color(0xFF111111);
const TextStyle _bodyStyle =
    TextStyle(fontSize: LayoutConst.bodyFont, color: _ink, height: 1.25);
const TextStyle _qStyle = TextStyle(
    fontSize: LayoutConst.bodyFont + 0.5,
    color: _ink,
    fontWeight: FontWeight.w600,
    height: 1.3);

/// A question rendered like printed paper. Tap it to reveal editing controls;
/// every text is editable in place.
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
    final selected = context.select<AppState, bool>(
        (s) => s.selectedId == question.id);
    final q = question;

    return Focus(
      onFocusChange: (has) {
        if (has) state.select(q.id);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => state.select(q.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: selected ? accent.withOpacity(0.06) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: selected ? accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected) _toolbar(state),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Text('Q$number.',
                        style: _qStyle.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: InlineTextField(
                      key: ValueKey('q_${q.id}_$rev'),
                      initial: q.text,
                      hint: 'Type the question...',
                      style: _qStyle,
                      maxLines: null,
                      onChanged: (v) => q.text = v,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: Text('( ${q.marks} )',
                        style: _qStyle.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 2),
                child: _body(context, state, rev, selected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar(AppState state) {
    final q = question;
    Widget btn(IconData icon, String tip, VoidCallback onTap, {Color? color}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Tooltip(
            message: tip,
            child: Icon(icon, size: 17, color: color ?? Colors.grey.shade700),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (q.type == QuestionType.mcq)
            btn(q.mcqLayout.icon, 'Options: ${q.mcqLayout.label}',
                () => state.cycleMcqLayout(q), color: accent),
          const Spacer(),
          btn(Icons.tune, 'Advanced edit', onSettings),
          btn(Icons.copy, 'Duplicate', onDuplicate),
          btn(Icons.delete_outline, 'Delete', onDelete, color: Colors.red),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppState state, int rev, bool selected) {
    final q = question;
    switch (q.type) {
      case QuestionType.mcq:
        return _mcq(state, rev, selected);
      case QuestionType.trueFalse:
        return _trueFalse(state, selected);
      case QuestionType.shortQuestion:
        return const _BlankLines(lines: 2);
      case QuestionType.longQuestion:
        return const _BlankLines(lines: 5);
      case QuestionType.fillBlank:
        return selected
            ? Text('Use ____ in the question text to mark a blank.',
                style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500))
            : const SizedBox(height: 2);
      case QuestionType.fillBlankWithOptions:
        return _wordBank(state, rev, selected);
      case QuestionType.columnMatch:
        return _match(state, rev, selected);
      case QuestionType.preschoolImage:
        return _preschool(state, rev);
    }
  }

  // ---- MCQ with three layouts ---------------------------------------------
  Widget _mcq(AppState state, int rev, bool selected) {
    final q = question;

    Widget optionLabel(int i) {
      final isCorrect = q.correctOption == i;
      return GestureDetector(
        onTap: () {
          q.correctOption = i;
          state.touch();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: (selected && isCorrect)
                ? accent.withOpacity(0.18)
                : Colors.transparent,
          ),
          child: Text('(${String.fromCharCode(65 + i)})',
              style: _bodyStyle.copyWith(
                  fontWeight:
                      isCorrect ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }

    Widget field(int i) => InlineTextField(
          key: ValueKey('optf_${q.id}_${i}_$rev'),
          initial: q.options[i],
          hint: 'Option ${String.fromCharCode(65 + i)}',
          style: _bodyStyle,
          onChanged: (v) => q.options[i] = v,
        );

    Widget removeBtn(int i) => selected && q.options.length > 2
        ? InkWell(
            onTap: () {
              q.options.removeAt(i);
              if (q.correctOption != null &&
                  q.correctOption! >= q.options.length) {
                q.correctOption = q.options.length - 1;
              }
              state.updatePaperHeader();
            },
            child: Icon(Icons.close, size: 13, color: Colors.grey.shade400),
          )
        : const SizedBox.shrink();

    final addBtn = selected
        ? Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 26),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add option', style: TextStyle(fontSize: 11)),
              onPressed: () {
                q.options.add('');
                state.updatePaperHeader();
              },
            ),
          )
        : const SizedBox.shrink();

    // Inline row layout.
    if (q.mcqLayout == McqLayout.row) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < q.options.length; i++)
                IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [optionLabel(i), field(i), removeBtn(i)],
                  ),
                ),
            ],
          ),
          addBtn,
        ],
      );
    }

    // Two-column grid layout.
    if (q.mcqLayout == McqLayout.twoColumn) {
      return LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 16) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 2,
              children: [
                for (var i = 0; i < q.options.length; i++)
                  SizedBox(
                    width: w,
                    child: Row(
                      children: [
                        optionLabel(i),
                        Expanded(child: field(i)),
                        removeBtn(i),
                      ],
                    ),
                  ),
              ],
            ),
            addBtn,
          ],
        );
      });
    }

    // Single-column layout (default), draggable to reorder when selected.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: q.options.length,
          onReorder: (o, n) => state.reorderOptions(q, o, n),
          itemBuilder: (context, i) => Padding(
            key: ValueKey('opt_${q.id}_${i}_$rev'),
            padding: const EdgeInsets.symmetric(vertical: 0.5),
            child: Row(
              children: [
                if (selected)
                  ReorderableDragStartListener(
                    index: i,
                    child: Icon(Icons.drag_indicator,
                        size: 14, color: Colors.grey.shade400),
                  ),
                optionLabel(i),
                Expanded(child: field(i)),
                removeBtn(i),
              ],
            ),
          ),
        ),
        addBtn,
      ],
    );
  }

  Widget _trueFalse(AppState state, bool selected) {
    final q = question;
    Widget opt(String label, bool value) {
      final isCorrect = q.isTrue == value;
      return GestureDetector(
        onTap: () {
          q.isTrue = value;
          state.touch();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 18),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: (selected && isCorrect)
                ? accent.withOpacity(0.18)
                : Colors.transparent,
          ),
          child: Text('(    )  $label',
              style: _bodyStyle.copyWith(
                  fontWeight:
                      isCorrect ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }

    return Row(children: [opt('True', true), opt('False', false)]);
  }

  Widget _wordBank(AppState state, int rev, bool selected) {
    final q = question;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Word Bank:',
              style: _bodyStyle.copyWith(fontWeight: FontWeight.bold)),
          for (var i = 0; i < q.wordBank.length; i++)
            SizedBox(
              width: 90,
              child: InlineTextField(
                key: ValueKey('wb_${q.id}_${i}_$rev'),
                initial: q.wordBank[i],
                hint: 'word',
                style: _bodyStyle,
                onChanged: (v) => q.wordBank[i] = v,
              ),
            ),
          if (selected)
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

  Widget _match(AppState state, int rev, bool selected) {
    final q = question;
    return Column(
      children: [
        for (var i = 0; i < q.pairs.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text('${i + 1}.',
                    style: _bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Expanded(
                  child: InlineTextField(
                    key: ValueKey('ml_${q.id}_${i}_$rev'),
                    initial: q.pairs[i].left,
                    hint: 'Column A',
                    style: _bodyStyle,
                    onChanged: (v) => q.pairs[i].left = v,
                  ),
                ),
                const SizedBox(width: 8),
                Text('(${String.fromCharCode(97 + i)})',
                    style: _bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                Expanded(
                  child: InlineTextField(
                    key: ValueKey('mr_${q.id}_${i}_$rev'),
                    initial: q.pairs[i].right,
                    hint: 'Column B',
                    style: _bodyStyle,
                    onChanged: (v) => q.pairs[i].right = v,
                  ),
                ),
                if (selected && q.pairs.length > 2)
                  InkWell(
                    onTap: () {
                      q.pairs.removeAt(i);
                      state.updatePaperHeader();
                    },
                    child: Icon(Icons.close,
                        size: 13, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        if (selected)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 26),
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
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(q.imageBytes!, height: 88),
            ),
          )
        else
          SizedBox(
            width: 180,
            child: InlineTextField(
              key: ValueKey('emoji_${q.id}_$rev'),
              initial: q.emoji ?? '',
              hint: 'Emoji 🍎🍎🍎 (or attach image in advanced)',
              style: const TextStyle(fontSize: 26),
              onChanged: (v) => q.emoji = v,
            ),
          ),
        if (q.options.isNotEmpty)
          Wrap(
            spacing: 14,
            children: [
              for (var i = 0; i < q.options.length; i++)
                SizedBox(
                  width: 96,
                  child: Row(
                    children: [
                      const Text('☐ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: InlineTextField(
                          key: ValueKey('pso_${q.id}_${i}_$rev'),
                          initial: q.options[i],
                          hint: 'choice',
                          style: _bodyStyle,
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
            height: 0.8,
            color: Colors.grey.shade400,
          ),
      ],
    );
  }
}
