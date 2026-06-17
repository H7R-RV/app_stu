import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../state/app_state.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String _subject = 'All';
  String _grade = 'All';
  QuestionType? _type;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = state.filteredBank(
      subject: _subject,
      grade: _grade,
      type: _type,
      search: _search,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search questions...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _dropdown(
                'Subject',
                _subject,
                ['All', ...state.subjects],
                (v) => setState(() => _subject = v!),
              ),
              const SizedBox(width: 8),
              _dropdown(
                'Grade',
                _grade,
                ['All', ...state.grades],
                (v) => setState(() => _grade = v!),
              ),
              const SizedBox(width: 8),
              _typeChips(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Text('${results.length} questions',
                  style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.bolt),
                label: const Text('Quick fill paper'),
                onPressed: () {
                  state.quickFill(
                    subject: _subject == 'All' ? null : _subject,
                    grade: _grade == 'All' ? null : _grade,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('A sample paper was generated.')),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('No questions match the filters.'))
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final q = results[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(q.type.shortLabel.substring(0, 1)),
                      ),
                      title: Text(
                        q.text.isEmpty ? '(no text)' : q.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                          '${q.type.label} • ${q.subject} • ${q.grade} • ${q.marks} mark(s)'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Add to paper',
                        onPressed: () {
                          state.addToPaper(q);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Added to paper.'),
                              duration: const Duration(milliseconds: 700),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String hint,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButton<String>(
      value: value,
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _typeChips() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('All types'),
          selected: _type == null,
          onSelected: (_) => setState(() => _type = null),
        ),
        for (final t in QuestionType.values) ...[
          const SizedBox(width: 6),
          ChoiceChip(
            label: Text(t.shortLabel),
            selected: _type == t,
            onSelected: (_) => setState(() => _type = t),
          ),
        ],
      ],
    );
  }
}
