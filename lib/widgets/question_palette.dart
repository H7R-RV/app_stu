import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'drag_payload.dart';

/// The left-hand library of questions. Drag an item onto the page, or tap it
/// to append it to the paper.
class QuestionPalette extends StatefulWidget {
  const QuestionPalette({super.key, this.onAdded});

  /// Called after a tap-to-add (used to close the drawer on narrow screens).
  final VoidCallback? onAdded;

  @override
  State<QuestionPalette> createState() => _QuestionPaletteState();
}

class _QuestionPaletteState extends State<QuestionPalette> {
  String _subject = 'All';
  QuestionType? _type;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = state.filteredBank(
      subject: _subject,
      type: _type,
      search: _search,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(gradient: AppTheme.appBarGradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Question Library',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Drag onto the page or tap to add',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, size: 18),
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _chip('All', _subject == 'All' && _type == null, () {
                setState(() {
                  _subject = 'All';
                  _type = null;
                });
              }),
              for (final s in state.subjects)
                _chip(s, _subject == s, () => setState(() => _subject = s)),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final t in QuestionType.values)
                _chip(t.shortLabel, _type == t, () {
                  setState(() => _type = _type == t ? null : t);
                }, color: AppTheme.typeColor(t.index)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('No matches'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: results.length,
                  itemBuilder: (_, i) => _PaletteItem(
                    question: results[i],
                    onAdded: widget.onAdded,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: (color ?? AppTheme.seed).withOpacity(0.18),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({required this.question, this.onAdded});
  final Question question;
  final VoidCallback? onAdded;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.typeColor(question.type.index);
    final state = context.read<AppState>();

    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.softShadow,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        title: Text(
          question.text.isEmpty ? '(no text)' : question.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Wrap(
            spacing: 6,
            children: [
              _tag(question.type.shortLabel, accent),
              _tag(question.subject, Colors.grey.shade500),
              _tag('${question.marks}m', Colors.grey.shade500),
            ],
          ),
        ),
        trailing: Icon(Icons.add_circle, color: accent, size: 20),
        onTap: () {
          state.addToPaper(question);
          onAdded?.call();
        },
      ),
    );

    return Draggable<Object>(
      data: AddQuestionPayload(question),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppTheme.softShadow,
          ),
          child: Text(
            question.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
      child: card,
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
