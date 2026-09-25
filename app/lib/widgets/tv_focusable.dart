import 'package:flutter/material.dart';
import '../main.dart' show kAccent;

/// Wraps a card/tile so it visibly highlights when D-pad focus lands on it.
/// Fire TV/Android TV navigation is entirely focus-driven -- without this,
/// Material widgets are focusable but give almost no visual feedback, which
/// makes a grid feel broken on a remote even though it "works".
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _focused ? kAccent : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: _focused
                  ? [BoxShadow(color: kAccent.withOpacity(0.35), blurRadius: 14, spreadRadius: 1)]
                  : const [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
