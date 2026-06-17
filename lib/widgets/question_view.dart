import 'package:flutter/material.dart';

import '../models/question.dart';

/// Renders a single question the way it will appear on the printed paper.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.number,
    this.showAnswers = false,
  });

  final Question question;
  final int number;
  final bool showAnswers;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q$number. ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                q.text.isEmpty ? '(tap to edit this question)' : q.text,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text('(${q.marks})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: _body(context),
        ),
        if (showAnswers && _answerLine(q).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4),
            child: Text('Answer: ${_answerLine(q)}',
                style: const TextStyle(
                    color: Colors.green, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final q = question;
    switch (q.type) {
      case QuestionType.mcq:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text('(${String.fromCharCode(65 + i)})  ${q.options[i]}'),
              ),
          ],
        );

      case QuestionType.trueFalse:
        return const Text('(  ) True        (  ) False');

      case QuestionType.shortQuestion:
        return const _AnswerLines(lines: 2);

      case QuestionType.longQuestion:
        return const _AnswerLines(lines: 5);

      case QuestionType.fillBlank:
        return const Text('Write your answer in the blank above.');

      case QuestionType.fillBlankWithOptions:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              const Text('Word Bank: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final w in q.wordBank)
                Text(w, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );

      case QuestionType.columnMatch:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Column A',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var i = 0; i < q.pairs.length; i++)
                    Text('${i + 1}. ${q.pairs[i].left}'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Column B',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var i = 0; i < q.pairs.length; i++)
                    Text(
                        '(${String.fromCharCode(97 + i)}) ${q.pairs[i].right}'),
                ],
              ),
            ),
          ],
        );

      case QuestionType.preschoolImage:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q.imageBytes != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Image.memory(q.imageBytes!, height: 80),
              )
            else if ((q.emoji ?? '').isNotEmpty)
              Text(q.emoji!, style: const TextStyle(fontSize: 32)),
            if (q.options.isNotEmpty)
              Row(
                children: [
                  for (final o in q.options)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text('☐ $o'),
                    ),
                ],
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 60,
                height: 36,
                decoration: BoxDecoration(border: Border.all()),
              ),
          ],
        );
    }
  }

  static String _answerLine(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        if (q.correctOption != null &&
            q.correctOption! >= 0 &&
            q.correctOption! < q.options.length) {
          return '(${String.fromCharCode(65 + q.correctOption!)}) '
              '${q.options[q.correctOption!]}';
        }
        return '';
      case QuestionType.trueFalse:
        return q.isTrue == null ? '' : (q.isTrue! ? 'True' : 'False');
      case QuestionType.columnMatch:
        return q.pairs
            .asMap()
            .entries
            .map((e) =>
                '${e.key + 1}-${String.fromCharCode(97 + e.key)}')
            .join(', ');
      default:
        return q.answer;
    }
  }
}

class _AnswerLines extends StatelessWidget {
  const _AnswerLines({required this.lines});
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lines; i++)
          Container(
            margin: const EdgeInsets.only(top: 14),
            height: 1,
            color: Colors.grey.shade400,
          ),
      ],
    );
  }
}
