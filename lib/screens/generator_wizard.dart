import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/generator.dart';
import '../models/question.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'generated_preview.dart';

class GeneratorWizard extends StatefulWidget {
  const GeneratorWizard({super.key});

  @override
  State<GeneratorWizard> createState() => _GeneratorWizardState();
}

class _GeneratorWizardState extends State<GeneratorWizard> {
  final GeneratorConfig config = GeneratorConfig();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final subjects = ['All', ...state.subjects];
    final grades = ['All', ...state.grades];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Test Paper',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.appBarGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Paper details'),
          _text('School / Institute', config.schoolName,
              (v) => config.schoolName = v),
          _text('Title', config.title, (v) => config.title = v),
          Row(children: [
            Expanded(child: _dropdown('Subject', config.subject, subjects,
                (v) => setState(() => config.subject = v))),
            const SizedBox(width: 10),
            Expanded(child: _dropdown('Class', config.grade, grades,
                (v) => setState(() => config.grade = v))),
          ]),
          Row(children: [
            Expanded(child: _text('Time', config.timeAllowed,
                (v) => config.timeAllowed = v)),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdown(
                'Difficulty',
                _difficultyLabel(config.difficulty),
                Difficulty.values.map(_difficultyLabel).toList(),
                (v) => setState(() => config.difficulty = Difficulty.values
                    .firstWhere((d) => _difficultyLabel(d) == v)),
              ),
            ),
          ]),
          _text('Instructions', config.instructions,
              (v) => config.instructions = v, maxLines: 2),
          const SizedBox(height: 8),
          _section('Options'),
          _stepperRow('Number of sets (A, B, C…)', config.sets, 1, 6,
              (v) => setState(() => config.sets = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shuffle question order in extra sets'),
            value: config.shuffleQuestions,
            onChanged: (v) => setState(() => config.shuffleQuestions = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shuffle MCQ options in extra sets'),
            value: config.shuffleOptions,
            onChanged: (v) => setState(() => config.shuffleOptions = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Generate answer key'),
            value: config.answerKey,
            onChanged: (v) => setState(() => config.answerKey = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _section('Sections'),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () => setState(() => config.sections.add(SectionSpec(
                    name: 'Section ${String.fromCharCode(65 + config.sections.length)}',
                    type: QuestionType.shortQuestion))),
              ),
            ],
          ),
          for (var i = 0; i < config.sections.length; i++)
            _sectionCard(i),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.seed,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text('Generate  •  ${config.totalMarks} marks',
            style: const TextStyle(color: Colors.white)),
        onPressed: () {
          final paper = generatePaper(config, state.bank);
          final empty = paper.sets.isEmpty ||
              paper.sets.first.sections.every((s) => s.questions.isEmpty);
          if (empty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'No questions match these filters. Try "All" subject/class or different types.')));
            return;
          }
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GeneratedPreview(paper: paper)));
        },
      ),
    );
  }

  Widget _sectionCard(int i) {
    final s = config.sections[i];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: s.name,
                    decoration: const InputDecoration(
                        labelText: 'Section name', isDense: true),
                    onChanged: (v) => s.name = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: config.sections.length <= 1
                      ? null
                      : () => setState(() => config.sections.removeAt(i)),
                ),
              ],
            ),
            DropdownButtonFormField<QuestionType>(
              value: s.type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Question type', isDense: true),
              items: [
                for (final t in QuestionType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() {
                if (v != null) {
                  s.type = v;
                  s.instruction = SectionSpec(name: s.name, type: v).instruction;
                }
              }),
            ),
            Row(
              children: [
                Expanded(
                    child: _stepperRow('Questions', s.count, 1, 30,
                        (v) => setState(() => s.count = v))),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _stepperRow('Marks each', s.marksEach, 1, 20,
                        (v) => setState(() => s.marksEach = v))),
                Text('= ${s.sectionMarks} marks',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.seed)),
      );

  Widget _text(String label, String value, ValueChanged<String> onChanged,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder(), isDense: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder(), isDense: true),
        items: [
          for (final it in items) DropdownMenuItem(value: it, child: Text(it)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _stepperRow(String label, int value, int min, int max,
      ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value <= min ? null : () => onChanged(value - 1),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value >= max ? null : () => onChanged(value + 1),
        ),
      ],
    );
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.any:
        return 'Any';
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}
