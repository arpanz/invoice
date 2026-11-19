import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}

/// A wrapper that smoothly slides & fades in children on load.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayStep;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 50),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  /// Rows only animate as part of the batch that appears together when a
  /// list loads. Rows built later (scrolled into view, or scrolled back)
  /// appear at once instead of waiting and re-animating.
  static DateTime _batchStart = DateTime.fromMillisecondsSinceEpoch(0);
  static const _batchWindow = Duration(milliseconds: 700);
  static DateTime _lastBuilt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The delay never grows past this many steps.
  static const _maxSteps = 8;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final now = DateTime.now();
    // A new batch starts with a first row built after a quiet moment (a
    // list loading), not while rows are being built by scrolling.
    if (widget.index == 0 && now.difference(_lastBuilt) > const Duration(milliseconds: 400)) {
      _batchStart = now;
    }
    _lastBuilt = now;
    final inBatch = now.difference(_batchStart) < _batchWindow;

    // Respect the system "remove animations" setting.
    if (MediaQuery.maybeDisableAnimationsOf(context) == true || !inBatch) {
      _controller.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, _maxSteps);
    Future.delayed(widget.delayStep * steps, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
