import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/header_config.dart';
import '../models/test_paper.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'inline_text_field.dart';

/// The editable header band. Tap any text to edit it, or open the options
/// (gear) to switch templates and toggle which fields appear.
class PaperHeaderView extends StatelessWidget {
  const PaperHeaderView({super.key, required this.paper, required this.revision});

  final TestPaper paper;
  final int revision;

  @override
  Widget build(BuildContext context) {
    final c = paper.header;
    return Stack(
      children: [
        switch (c.template) {
          HeaderTemplate.modern => _modern(context),
          HeaderTemplate.classic => _classic(context),
          HeaderTemplate.compact => _compact(context),
          HeaderTemplate.formal => _formal(context),
        },
        Positioned(
          right: -6,
          top: -6,
          child: IconButton(
            tooltip: 'Header options',
            icon: const Icon(Icons.tune, size: 18),
            onPressed: () => _openOptions(context),
          ),
        ),
      ],
    );
  }

  // ---- Reusable pieces -----------------------------------------------------

  Widget _logo(double size) {
    final c = paper.header;
    if (!c.showLogo) return const SizedBox.shrink();
    if (c.logoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(c.logoBytes!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Text(c.logoEmoji, style: TextStyle(fontSize: size * 0.8));
  }

  Widget _school(double fontSize, {Color? color}) {
    final c = paper.header;
    if (!c.showSchool) return const SizedBox.shrink();
    return InlineTextField(
      key: ValueKey('h_school_$revision'),
      initial: paper.schoolName,
      hint: 'School name',
      textAlign: c.centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
      onChanged: (v) => paper.schoolName = v,
    );
  }

  Widget _title(double fontSize, {Color? color}) {
    final c = paper.header;
    if (!c.showTitle) return const SizedBox.shrink();
    return InlineTextField(
      key: ValueKey('h_title_$revision'),
      initial: paper.title,
      hint: 'Exam title',
      textAlign: c.centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
      onChanged: (v) => paper.title = v,
    );
  }

  Widget _metaField(String label, String key, String value, ValueChanged<String> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        SizedBox(
          width: 86,
          child: InlineTextField(
            key: ValueKey('$key$revision'),
            initial: value,
            style: const TextStyle(fontSize: 12),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  List<Widget> _metaFields() {
    final c = paper.header;
    return [
      if (c.showSubject)
        _metaField('Subject', 'h_sub_', paper.subject, (v) => paper.subject = v),
      if (c.showClass)
        _metaField('Class', 'h_cls_', paper.grade, (v) => paper.grade = v),
      if (c.showTime)
        _metaField('Time', 'h_time_', paper.timeAllowed, (v) => paper.timeAllowed = v),
      if (c.showMarks)
        Text('Total Marks: ${paper.totalMarks}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ];
  }

  Widget _studentLine() {
    final c = paper.header;
    if (!c.showName && !c.showRoll && !c.showDate) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (c.showName)
            const Expanded(
                child: Text('Name: ____________________',
                    style: TextStyle(fontSize: 12))),
          if (c.showRoll)
            const Text('Roll No: __________', style: TextStyle(fontSize: 12)),
          if (c.showDate) ...[
            const SizedBox(width: 8),
            const Text('Date: ', style: TextStyle(fontSize: 12)),
            SizedBox(
              width: 80,
              child: InlineTextField(
                key: ValueKey('h_date_$revision'),
                initial: c.date,
                hint: '__/__/__',
                style: const TextStyle(fontSize: 12),
                onChanged: (v) => c.date = v,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _instructions() {
    final c = paper.header;
    if (!c.showInstructions) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InlineTextField(
        key: ValueKey('h_instr_$revision'),
        initial: paper.instructions,
        hint: 'Instructions...',
        maxLines: null,
        style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade700),
        onChanged: (v) => paper.instructions = v,
      ),
    );
  }

  // ---- Templates -----------------------------------------------------------

  Widget _modern(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.seed.withOpacity(0.12),
              AppTheme.accent.withOpacity(0.12),
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _logo(40),
              if (paper.header.showLogo) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_school(19), _title(14)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 14, runSpacing: 2, children: _metaFields()),
        _studentLine(),
        _instructions(),
      ],
    );
  }

  Widget _classic(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paper.header.showLogo) Center(child: _logo(38)),
        _school(20),
        _title(15),
        const Divider(thickness: 1.4, height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _metaFields()
              .map((w) => Flexible(child: w))
              .toList(),
        ),
        _studentLine(),
        _instructions(),
        const Divider(thickness: 1.4, height: 12),
      ],
    );
  }

  Widget _compact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _logo(26),
            if (paper.header.showLogo) const SizedBox(width: 8),
            Expanded(child: _school(16)),
            Expanded(child: _title(13)),
          ],
        ),
        const Divider(height: 8),
        Wrap(spacing: 12, children: _metaFields()),
        _studentLine(),
        _instructions(),
      ],
    );
  }

  Widget _formal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _logo(40),
              if (paper.header.showLogo) const SizedBox(width: 10),
              Expanded(
                child: Column(children: [_school(18), _title(14)]),
              ),
            ],
          ),
          const Divider(thickness: 1, height: 12),
          Wrap(spacing: 16, runSpacing: 2, children: _metaFields()),
          _studentLine(),
          _instructions(),
        ],
      ),
    );
  }

  // ---- Options sheet -------------------------------------------------------

  void _openOptions(BuildContext context) {
    final state = context.read<AppState>();
    final c = paper.header;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void change(VoidCallback fn) {
              setSheet(fn);
              state.updatePaperHeader();
            }

            Widget toggle(String label, bool value, ValueChanged<bool> on) {
              return FilterChip(
                label: Text(label),
                selected: value,
                onSelected: (v) => change(() => on(v)),
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              builder: (ctx, scroll) => ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Header template',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in HeaderTemplate.values)
                        ChoiceChip(
                          label: Text(t.label),
                          selected: c.template == t,
                          onSelected: (_) => change(() => c.template = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Center the school name & title'),
                    value: c.centered,
                    onChanged: (v) => change(() => c.centered = v),
                  ),
                  const Divider(),
                  const Text('Show fields',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      toggle('Logo', c.showLogo, (v) => c.showLogo = v),
                      toggle('School', c.showSchool, (v) => c.showSchool = v),
                      toggle('Title', c.showTitle, (v) => c.showTitle = v),
                      toggle('Subject', c.showSubject, (v) => c.showSubject = v),
                      toggle('Class', c.showClass, (v) => c.showClass = v),
                      toggle('Time', c.showTime, (v) => c.showTime = v),
                      toggle('Total marks', c.showMarks, (v) => c.showMarks = v),
                      toggle('Name', c.showName, (v) => c.showName = v),
                      toggle('Roll no', c.showRoll, (v) => c.showRoll = v),
                      toggle('Date', c.showDate, (v) => c.showDate = v),
                      toggle('Instructions', c.showInstructions,
                          (v) => c.showInstructions = v),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Logo', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Attach image'),
                        onPressed: () async {
                          final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 400,
                              imageQuality: 85);
                          if (file != null) {
                            final bytes = await file.readAsBytes();
                            change(() => c.logoBytes = bytes);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      if (c.logoBytes != null)
                        TextButton(
                          onPressed: () => change(() => c.logoBytes = null),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Emoji logo: '),
                      const SizedBox(width: 8),
                      for (final e in ['🏫', '📘', '🎓', '✏️', '⭐', '🧮'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => change(() => c.logoEmoji = e),
                            child: Text(e,
                                style: TextStyle(
                                    fontSize: 24,
                                    color: c.logoEmoji == e
                                        ? null
                                        : Colors.grey.shade400)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
