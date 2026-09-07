import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// A "swipe to confirm" bar — admin drags the thumb to the end to trigger
/// [onConfirm]. Used for one-directional status advances (order/lab-test
/// status flows) where free-choice status jumping isn't allowed; cancelling
/// is a separate, always-available control elsewhere on the screen, not
/// part of this bar.
class StatusSwipeBar extends StatefulWidget {
  const StatusSwipeBar({super.key, required this.label, required this.onConfirm, this.enabled = true});

  final String label;
  final VoidCallback onConfirm;
  final bool enabled;

  @override
  State<StatusSwipeBar> createState() => _StatusSwipeBarState();
}

class _StatusSwipeBarState extends State<StatusSwipeBar> {
  static const _thumbSize = 48.0;
  static const _confirmThreshold = 0.75;

  double _dragExtent = 0; // 0..1, fraction of the available track
  bool _confirmed = false;

  @override
  void didUpdateWidget(covariant StatusSwipeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new label means this bar now represents a different transition
    // (the parent moved to the next status) — reset rather than carry over
    // a stale confirmed/dragged state from the previous one.
    if (oldWidget.label != widget.label) {
      _dragExtent = 0;
      _confirmed = false;
    }
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!widget.enabled || _confirmed || maxDrag <= 0) return;
    setState(() {
      final current = _dragExtent * maxDrag + details.delta.dx;
      _dragExtent = current.clamp(0, maxDrag) / maxDrag;
    });
  }

  void _onDragEnd() {
    if (!widget.enabled || _confirmed) return;
    if (_dragExtent >= _confirmThreshold) {
      setState(() {
        _confirmed = true;
        _dragExtent = 1;
      });
      widget.onConfirm();
    } else {
      setState(() => _dragExtent = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackColor = widget.enabled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final onTrackColor = widget.enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant;
    final thumbColor = widget.enabled ? theme.colorScheme.primary : theme.colorScheme.outline;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize;
        final thumbLeft = _dragExtent * maxDrag;
        return Container(
          height: _thumbSize,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _thumbSize + AppConstants.spacingSm),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(color: onTrackColor),
                ),
              ),
              AnimatedPositioned(
                duration: _confirmed || _dragExtent == 0
                    ? const Duration(milliseconds: 150)
                    : Duration.zero,
                curve: Curves.easeOut,
                left: thumbLeft,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (_) => _onDragEnd(),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: thumbColor),
                    child: Icon(
                      _confirmed ? Icons.check : Icons.chevron_right,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
