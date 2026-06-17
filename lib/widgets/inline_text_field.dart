import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// A borderless text field that writes straight into the model and re-flows
/// the pages when it loses focus (so layout stays stable while typing).
class InlineTextField extends StatefulWidget {
  const InlineTextField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.hint,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign textAlign;

  @override
  State<InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<InlineTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && mounted) context.read<AppState>().reflow();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: _controller,
      focusNode: _focus,
      maxLines: widget.maxLines,
      style: widget.style,
      textAlign: widget.textAlign,
      cursorColor: primary,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        hintText: widget.hint,
        hintStyle: (widget.style ?? const TextStyle()).copyWith(
            color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: primary, width: 1.4)),
      ),
      onChanged: widget.onChanged,
    );
  }
}
