import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../state/app_state.dart';

/// Full-screen editor for a single question already placed on the paper.
class QuestionEditor extends StatefulWidget {
  const QuestionEditor({super.key, required this.question});

  final Question question;

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late final Question q = widget.question;

  void _refresh() {
    setState(() {});
    context.read<AppState>().touch();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    q.imageBytes = bytes;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${q.type.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Question text', q.text, (v) => q.text = v, maxLines: 3),
          Row(
            children: [
              Expanded(
                child: _field('Subject', q.subject, (v) => q.subject = v),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field('Grade', q.grade, (v) => q.grade = v)),
            ],
          ),
          _marksField(),
          const Divider(height: 32),
          ..._typeFields(),
        ],
      ),
    );
  }

  List<Widget> _typeFields() {
    switch (q.type) {
      case QuestionType.mcq:
        return _mcqFields();
      case QuestionType.trueFalse:
        return _trueFalseFields();
      case QuestionType.shortQuestion:
      case QuestionType.longQuestion:
      case QuestionType.fillBlank:
        return [
          if (q.type == QuestionType.fillBlank)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Tip: use ____ inside the text to mark a blank.',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          _field('Answer key', q.answer, (v) => q.answer = v, maxLines: 2),
        ];
      case QuestionType.fillBlankWithOptions:
        return _wordBankFields();
      case QuestionType.columnMatch:
        return _matchFields();
      case QuestionType.preschoolImage:
        return _preschoolFields();
    }
  }

  // ---- MCQ -----------------------------------------------------------------
  List<Widget> _mcqFields() {
    return [
      const Text('Options (select the correct one)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (var i = 0; i < q.options.length; i++)
        Row(
          children: [
            Radio<int>(
              value: i,
              groupValue: q.correctOption,
              onChanged: (v) {
                q.correctOption = v;
                _refresh();
              },
            ),
            Expanded(
              child: _field(
                'Option ${String.fromCharCode(65 + i)}',
                q.options[i],
                (v) => q.options[i] = v,
                dense: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: q.options.length <= 2
                  ? null
                  : () {
                      q.options.removeAt(i);
                      if (q.correctOption != null &&
                          q.correctOption! >= q.options.length) {
                        q.correctOption = q.options.length - 1;
                      }
                      _refresh();
                    },
            ),
          ],
        ),
      TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add option'),
        onPressed: () {
          q.options.add('');
          _refresh();
        },
      ),
    ];
  }

  // ---- True / False --------------------------------------------------------
  List<Widget> _trueFalseFields() {
    return [
      const Text('Correct answer',
          style: TextStyle(fontWeight: FontWeight.bold)),
      RadioListTile<bool>(
        title: const Text('True'),
        value: true,
        groupValue: q.isTrue,
        onChanged: (v) {
          q.isTrue = v;
          _refresh();
        },
      ),
      RadioListTile<bool>(
        title: const Text('False'),
        value: false,
        groupValue: q.isTrue,
        onChanged: (v) {
          q.isTrue = v;
          _refresh();
        },
      ),
    ];
  }

  // ---- Word bank fill ------------------------------------------------------
  List<Widget> _wordBankFields() {
    return [
      const Text('Word bank (shown at the top of the question)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (var i = 0; i < q.wordBank.length; i++)
        Row(
          children: [
            Expanded(
              child: _field('Word ${i + 1}', q.wordBank[i],
                  (v) => q.wordBank[i] = v,
                  dense: true),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                q.wordBank.removeAt(i);
                _refresh();
              },
            ),
          ],
        ),
      TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add word'),
        onPressed: () {
          q.wordBank.add('');
          _refresh();
        },
      ),
      const SizedBox(height: 8),
      _field('Answer key', q.answer, (v) => q.answer = v, maxLines: 2),
    ];
  }

  // ---- Column match --------------------------------------------------------
  List<Widget> _matchFields() {
    return [
      const Text('Matching pairs (Column A → Column B)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (var i = 0; i < q.pairs.length; i++)
        Row(
          children: [
            Expanded(
              child: _field('A${i + 1}', q.pairs[i].left,
                  (v) => q.pairs[i].left = v,
                  dense: true),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward),
            ),
            Expanded(
              child: _field('B${i + 1}', q.pairs[i].right,
                  (v) => q.pairs[i].right = v,
                  dense: true),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: q.pairs.length <= 2
                  ? null
                  : () {
                      q.pairs.removeAt(i);
                      _refresh();
                    },
            ),
          ],
        ),
      TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add pair'),
        onPressed: () {
          q.pairs.add(MatchPair(left: '', right: ''));
          _refresh();
        },
      ),
    ];
  }

  // ---- Pre-school ----------------------------------------------------------
  List<Widget> _preschoolFields() {
    return [
      _field('Emoji / picture characters (e.g. 🍎🍎🍎)', q.emoji ?? '',
          (v) => q.emoji = v),
      const SizedBox(height: 12),
      Row(
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('Attach image'),
            onPressed: _pickImage,
          ),
          const SizedBox(width: 12),
          if (q.imageBytes != null)
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              onPressed: () {
                q.imageBytes = null;
                _refresh();
              },
            ),
        ],
      ),
      if (q.imageBytes != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Image.memory(q.imageBytes!, height: 120),
        ),
      const Divider(height: 24),
      const Text('Optional answer choices (tick boxes on the paper)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      for (var i = 0; i < q.options.length; i++)
        Row(
          children: [
            Expanded(
              child: _field('Choice ${i + 1}', q.options[i],
                  (v) => q.options[i] = v,
                  dense: true),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                q.options.removeAt(i);
                _refresh();
              },
            ),
          ],
        ),
      TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add choice'),
        onPressed: () {
          q.options = [...q.options, ''];
          _refresh();
        },
      ),
      _field('Answer key', q.answer, (v) => q.answer = v),
    ];
  }

  // ---- Shared field builders ----------------------------------------------
  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    bool dense = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: dense,
        ),
        onChanged: (v) {
          onChanged(v);
          // Live-update the paper preview without rebuilding text fields.
          context.read<AppState>().touch();
        },
      ),
    );
  }

  Widget _marksField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Text('Marks: ', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: q.marks <= 1
                ? null
                : () {
                    q.marks--;
                    _refresh();
                  },
          ),
          Text('${q.marks}', style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              q.marks++;
              _refresh();
            },
          ),
        ],
      ),
    );
  }
}
