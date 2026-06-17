import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document.dart';
import '../models/page_size.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'element_view.dart';

/// Draws one white page at the real aspect ratio with all its elements.
class CanvasPage extends StatelessWidget {
  const CanvasPage({
    super.key,
    required this.page,
    required this.size,
    required this.displayWidth,
  });

  final DocPage page;
  final PaperSize size;
  final double displayWidth;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final scale = displayWidth / size.ptWidth;
    final height = size.ptHeight * scale;

    return Container(
      width: displayWidth,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.pageShadows,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tap empty space to deselect / stop editing.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                state.stopEditing();
                state.select(null);
              },
            ),
          ),
          for (final e in page.elements)
            ElementView(
              key: ValueKey(e.id),
              element: e,
              scale: scale,
              pageWpt: size.ptWidth,
              pageHpt: size.ptHeight,
            ),
        ],
      ),
    );
  }
}
