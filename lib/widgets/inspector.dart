import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/doc_element.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const List<int> _palette = [
  0xFF111111, 0xFFFFFFFF, 0xFFEF4444, 0xFFF59E0B, 0xFFFACC15,
  0xFF22C55E, 0xFF14B8A6, 0xFF0EA5E9, 0xFF4F46E5, 0xFF8B5CF6,
  0xFFEC4899, 0xFF6B7280, 0xFF92400E, 0xFF065F46, 0xFF1E3A8A,
];

/// The styling panel for the currently selected element.
class Inspector extends StatelessWidget {
  const Inspector({super.key, required this.element});
  final DocElement element;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final e = element;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(context, state, e),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(12),
            shrinkWrap: true,
            children: [
              if (e.isText) ..._textControls(context, state, e),
              if (e.type == ElementType.image) ..._imageControls(state, e),
              if (e.type == ElementType.rect || e.type == ElementType.ellipse)
                ..._shapeControls(state, e),
              if (e.type == ElementType.line) ..._lineControls(state, e),
              const SizedBox(height: 8),
              _label('Rotation  ${e.rotation.round()}°'),
              Slider(
                min: -180,
                max: 180,
                value: e.rotation.clamp(-180, 180),
                onChanged: (v) {
                  e.rotation = v;
                  state.touch();
                },
              ),
              _label('Opacity  ${(e.opacity * 100).round()}%'),
              Slider(
                min: 0.1,
                max: 1,
                value: e.opacity.clamp(0.1, 1),
                onChanged: (v) {
                  e.opacity = v;
                  state.touch();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, AppState state, DocElement e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Text(_typeName(e.type),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Bring forward',
            icon: const Icon(Icons.flip_to_front, size: 20),
            onPressed: () => state.bringForward(e.id),
          ),
          IconButton(
            tooltip: 'Send backward',
            icon: const Icon(Icons.flip_to_back, size: 20),
            onPressed: () => state.sendBackward(e.id),
          ),
          IconButton(
            tooltip: 'Duplicate',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => state.duplicate(e.id),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => state.delete(e.id),
          ),
        ],
      ),
    );
  }

  List<Widget> _textControls(BuildContext context, AppState state, DocElement e) {
    return [
      FilledButton.tonalIcon(
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Edit text'),
        onPressed: () => state.startEditing(e.id),
      ),
      const SizedBox(height: 12),
      _label('Font'),
      DropdownButtonFormField<String>(
        value: e.fontFamily,
        isDense: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: [
          for (final f in kFontFamilies)
            DropdownMenuItem(
              value: f,
              child: Text(f, style: TextStyle(fontFamily: f, fontSize: 16)),
            ),
        ],
        onChanged: (v) {
          if (v != null) {
            e.fontFamily = v;
            state.touch();
          }
        },
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _label('Size ${e.fontSize.round()}'),
          Expanded(
            child: Slider(
              min: 6,
              max: 96,
              value: e.fontSize.clamp(6, 96),
              onChanged: (v) {
                e.fontSize = v;
                state.touch();
              },
            ),
          ),
        ],
      ),
      Row(
        children: [
          _toggle(Icons.format_bold, e.bold, () {
            e.bold = !e.bold;
            state.touch();
          }),
          _toggle(Icons.format_italic, e.italic, () {
            e.italic = !e.italic;
            state.touch();
          }),
          _toggle(Icons.format_underlined, e.underline, () {
            e.underline = !e.underline;
            state.touch();
          }),
          const SizedBox(width: 12),
          _toggle(Icons.format_align_left, e.align == TextAlign.left, () {
            e.align = TextAlign.left;
            state.touch();
          }),
          _toggle(Icons.format_align_center, e.align == TextAlign.center, () {
            e.align = TextAlign.center;
            state.touch();
          }),
          _toggle(Icons.format_align_right, e.align == TextAlign.right, () {
            e.align = TextAlign.right;
            state.touch();
          }),
        ],
      ),
      const SizedBox(height: 10),
      _label('Text colour'),
      _swatches(e.color, (c) {
        e.color = c;
        state.touch();
      }),
      const SizedBox(height: 10),
      _label('Text background'),
      _swatches(e.fill, (c) {
        e.fill = c;
        state.touch();
      }, allowNone: true, onNone: () {
        e.fill = null;
        state.touch();
      }),
    ];
  }

  List<Widget> _imageControls(AppState state, DocElement e) {
    return [
      OutlinedButton.icon(
        icon: const Icon(Icons.image),
        label: const Text('Replace image'),
        onPressed: () async {
          final file = await ImagePicker()
              .pickImage(source: ImageSource.gallery, imageQuality: 85);
          if (file != null) {
            e.imageBytes = await file.readAsBytes();
            state.touch();
          }
        },
      ),
    ];
  }

  List<Widget> _shapeControls(AppState state, DocElement e) {
    return [
      _label('Fill'),
      _swatches(e.fill, (c) {
        e.fill = c;
        state.touch();
      }, allowNone: true, onNone: () {
        e.fill = null;
        state.touch();
      }),
      const SizedBox(height: 10),
      _label('Border colour'),
      _swatches(e.strokeColor, (c) {
        e.strokeColor = c;
        state.touch();
      }),
      _label('Border width ${e.strokeWidth.round()}'),
      Slider(
        min: 0,
        max: 12,
        value: e.strokeWidth.clamp(0, 12),
        onChanged: (v) {
          e.strokeWidth = v;
          state.touch();
        },
      ),
    ];
  }

  List<Widget> _lineControls(AppState state, DocElement e) {
    return [
      _label('Colour'),
      _swatches(e.strokeColor, (c) {
        e.strokeColor = c;
        e.color = c;
        state.touch();
      }),
      _label('Thickness ${e.h.round()}'),
      Slider(
        min: 1,
        max: 20,
        value: e.h.clamp(1, 20),
        onChanged: (v) {
          e.h = v;
          state.touch();
        },
      ),
    ];
  }

  Widget _swatches(int? selected, ValueChanged<int> onPick,
      {bool allowNone = false, VoidCallback? onNone}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (allowNone)
          GestureDetector(
            onTap: onNone,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected == null ? AppTheme.seed : Colors.grey,
                    width: selected == null ? 2 : 1),
              ),
              child: const Icon(Icons.format_color_reset, size: 14),
            ),
          ),
        for (final c in _palette)
          GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? AppTheme.seed : Colors.grey.shade300,
                  width: selected == c ? 2.5 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toggle(IconData icon, bool on, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: on ? AppTheme.seed.withOpacity(0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: on ? AppTheme.seed : Colors.grey.shade300),
          ),
          child: Icon(icon, size: 18, color: on ? AppTheme.seed : null),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Text(t,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
      );

  String _typeName(ElementType t) {
    switch (t) {
      case ElementType.text:
        return 'Text';
      case ElementType.image:
        return 'Image';
      case ElementType.rect:
        return 'Rectangle';
      case ElementType.ellipse:
        return 'Ellipse';
      case ElementType.line:
        return 'Line';
    }
  }
}
