import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/test_paper.dart';
import '../state/app_state.dart';

class PaperSettingsScreen extends StatelessWidget {
  const PaperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final paper = state.paper;

    Widget field(String label, String value, ValueChanged<String> onChanged,
        {int maxLines = 1}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          initialValue: value,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            onChanged(v);
            state.updatePaperHeader();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paper Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field('School / Institute name', paper.schoolName,
              (v) => paper.schoolName = v),
          field('Paper title', paper.title, (v) => paper.title = v),
          Row(
            children: [
              Expanded(
                  child: field(
                      'Subject', paper.subject, (v) => paper.subject = v)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      field('Class / Grade', paper.grade, (v) => paper.grade = v)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: field('Teacher (optional)', paper.teacher,
                      (v) => paper.teacher = v)),
              const SizedBox(width: 12),
              Expanded(
                  child: field('Time allowed', paper.timeAllowed,
                      (v) => paper.timeAllowed = v)),
            ],
          ),
          field('Instructions', paper.instructions,
              (v) => paper.instructions = v,
              maxLines: 3),
          const SizedBox(height: 8),
          DropdownButtonFormField<PaperSize>(
            value: paper.size,
            decoration: const InputDecoration(
              labelText: 'Page size',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in PaperSize.values)
                DropdownMenuItem(
                  value: s,
                  child: Text('${s.label}  •  ${s.dimensionLabel}'),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                paper.size = v;
                state.updatePaperHeader();
              }
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Include answer key in export'),
            subtitle: const Text('Adds a key at the end of the PDF / Word file'),
            value: paper.showAnswerKey,
            onChanged: (v) {
              paper.showAnswerKey = v;
              state.updatePaperHeader();
            },
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Total questions'),
              trailing: Text('${paper.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Total marks'),
              trailing: Text('${paper.totalMarks}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
