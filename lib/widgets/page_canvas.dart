import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../models/test_paper.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'drag_payload.dart';
import 'editable_question.dart';
import 'page_layout.dart';
import 'paper_header_view.dart';

/// Renders the paper as one or more real-size pages that auto-flow content
/// onto new pages, with visible margins/padding and drag-and-drop support.
class PageCanvas extends StatelessWidget {
  const PageCanvas({
    super.key,
    required this.pageWidth,
    required this.onAdvancedEdit,
  });

  final double pageWidth;
  final void Function(Question) onAdvancedEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final paper = state.paper;
    final metrics = PaperMetrics(paper: paper, availableWidth: pageWidth);
    final pages = paginate(paper, metrics);

    return Column(
      children: [
        for (var p = 0; p < pages.length; p++)
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: _PageCard(
              metrics: metrics,
              pageNumber: p + 1,
              totalPages: pages.length,
              indices: pages[p],
              isFirst: p == 0,
              isLast: p == pages.length - 1,
              onAdvancedEdit: onAdvancedEdit,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: (80 * p).ms)
                .slideY(begin: 0.06, curve: Curves.easeOutCubic)
                .scaleXY(begin: 0.97, end: 1),
          ),
      ],
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.metrics,
    required this.pageNumber,
    required this.totalPages,
    required this.indices,
    required this.isFirst,
    required this.isLast,
    required this.onAdvancedEdit,
  });

  final PaperMetrics metrics;
  final int pageNumber;
  final int totalPages;
  final List<int> indices;
  final bool isFirst;
  final bool isLast;
  final void Function(Question) onAdvancedEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final paper = state.paper;

    return Container(
      width: metrics.pageWidth,
      height: metrics.pageHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: AppTheme.pageShadows,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Margin guide (dashed) to show the printable area.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(metrics.marginPx),
              child: CustomPaint(painter: _DashedBorderPainter()),
            ),
          ),
          // Content within margin + padding.
          Padding(
            padding: EdgeInsets.all(metrics.inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isFirst) ...[
                  PaperHeaderView(paper: paper, revision: state.revision),
                  const SizedBox(height: 6),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final g in indices) ...[
                        _DropZone(insertIndex: g),
                        _QuestionRow(
                          index: g,
                          question: paper.questions[g],
                          onAdvancedEdit: onAdvancedEdit,
                        ),
                      ],
                      if (isLast)
                        _DropZone(insertIndex: paper.questions.length),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Page number badge.
          Positioned(
            right: 8,
            bottom: 4,
            child: Text('Page $pageNumber / $totalPages',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ),
          // Paper-size watermark on the first page.
          if (isFirst)
            Positioned(
              left: 8,
              bottom: 4,
              child: Text(
                  '${paper.size.label} • ${paper.size.dimensionLabel}',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.question,
    required this.onAdvancedEdit,
  });

  final int index;
  final Question question;
  final void Function(Question) onAdvancedEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final accent = AppTheme.typeColor(question.type.index);

    final card = EditableQuestion(
      question: question,
      number: index + 1,
      accent: accent,
      onSettings: () => onAdvancedEdit(question),
      onDuplicate: () => state.duplicate(question.id),
      onDelete: () => state.removeFromPaper(question.id),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Draggable<Object>(
          data: MoveQuestionPayload(question.id),
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppTheme.softShadow,
              ),
              child: Text(
                'Q${index + 1}: ${question.text}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: Icon(Icons.drag_indicator, color: Colors.grey.shade400),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 2),
            child: Icon(Icons.drag_indicator,
                size: 18, color: accent.withOpacity(0.7)),
          ),
        ),
        Expanded(child: card),
      ],
    );
  }
}

/// A drop target between questions; accepts both new (palette) and moved items.
class _DropZone extends StatefulWidget {
  const _DropZone({required this.insertIndex});
  final int insertIndex;

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hover = true);
        return true;
      },
      onLeave: (_) => setState(() => _hover = false),
      onAcceptWithDetails: (details) {
        setState(() => _hover = false);
        final state = context.read<AppState>();
        final data = details.data;
        if (data is AddQuestionPayload) {
          state.addAt(data.source, widget.insertIndex);
        } else if (data is MoveQuestionPayload) {
          state.moveTo(data.id, widget.insertIndex);
        }
      },
      builder: (context, candidate, rejected) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _hover ? 26 : 8,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: _hover
                ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: _hover
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.4)
                : null,
          ),
          child: _hover
              ? Center(
                  child: Text('Drop here',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                )
              : null,
        );
      },
    );
  }
}

/// Paints a dashed rectangle to visualise the page margin / printable area.
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;

    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      var d = 0.0;
      while (d < total) {
        final start = a + dir * d;
        final end = a + dir * (d + dash).clamp(0, total);
        canvas.drawLine(start, end, paint);
        d += dash + gap;
      }
    }

    final r = Offset.zero & size;
    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
