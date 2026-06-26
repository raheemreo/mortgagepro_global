// lib/shared/widgets/deep_link_highlight_wrapper.dart

import 'package:flutter/material.dart';

/// Stateful wrapper to animate and highlight targeted calculator cards.
class DeepLinkHighlightWrapper extends StatefulWidget {
  final Widget child;
  final String toolId;
  final String? activeToolId;
  final Color highlightColor;

  const DeepLinkHighlightWrapper({
    super.key,
    required this.child,
    required this.toolId,
    required this.activeToolId,
    required this.highlightColor,
  });

  @override
  State<DeepLinkHighlightWrapper> createState() => _DeepLinkHighlightWrapperState();
}

class _DeepLinkHighlightWrapperState extends State<DeepLinkHighlightWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );

    // Matches CSS: 300ms scaling/glow fade-in, 1400ms hold, 300ms fade-out
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.03).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0, // 300ms (15% of 2s)
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.03),
        weight: 70.0, // 1400ms (70% of 2s)
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0, // 300ms (15% of 2s)
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0,
      ),
    ]).animate(_controller);

    if (widget.activeToolId == widget.toolId && !_hasPlayed) {
      _triggerHighlight();
    }
  }

  @override
  void didUpdateWidget(covariant DeepLinkHighlightWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger only if the targeted tool is matching and hasn't played on this navigation
    if (widget.activeToolId == widget.toolId && oldWidget.activeToolId != widget.toolId) {
      _hasPlayed = false;
      _triggerHighlight();
    }
  }

  void _triggerHighlight() {
    _hasPlayed = true;
    _controller.duration = const Duration(milliseconds: 2000);
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowValue = _glowAnimation.value;
        final scaleValue = _scaleAnimation.value;

        return Transform.scale(
          scale: scaleValue,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              boxShadow: glowValue > 0.01
                  ? [
                      BoxShadow(
                        color: widget.highlightColor.withValues(alpha: 0.35 * glowValue),
                        blurRadius: 18.0 * glowValue,
                        spreadRadius: 3.0 * glowValue,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
