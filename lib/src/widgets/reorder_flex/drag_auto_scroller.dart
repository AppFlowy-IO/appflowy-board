import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A custom auto-scroller that scrolls when dragging near the edges of a widget.
///
/// Unlike Flutter's [EdgeDraggingAutoScroller], this implementation uses the
/// widget's own [RenderBox] bounds rather than relying on [Scrollable.maybeOf],
/// which can find the wrong scrollable when the widget is nested in complex layouts.
///
/// This fixes the issue where auto-scroll doesn't work when the board is not
/// full screen width (e.g., wrapped in a Row with Expanded).
class BoardDragAutoScroller {
  BoardDragAutoScroller({
    required this.scrollController,
    required this.velocityScalar,
    required this.axis,
    this.onScrollViewScrolled,
  });

  final ScrollController scrollController;
  final double velocityScalar;
  final Axis axis;
  final VoidCallback? onScrollViewScrolled;

  /// The size of the edge area that triggers auto-scrolling.
  static const double _edgeSize = 80.0;

  /// Minimum velocity for auto-scrolling.
  static const double _minVelocity = 0.0;

  Ticker? _ticker;
  double _scrollVelocity = 0.0;
  GlobalKey? _containerKey;

  /// Sets the container key used to get the widget's bounds.
  void setContainerKey(GlobalKey key) {
    _containerKey = key;
  }

  /// Starts auto-scrolling if the drag position is near the edges.
  ///
  /// [dragRect] should be in global coordinates.
  /// [containerContext] is used to get the container's bounds if [_containerKey] is not set.
  void startAutoScrollIfNecessary(
    Rect dragRect, {
    BuildContext? containerContext,
  }) {
    if (!scrollController.hasClients) return;

    final containerRect = _getContainerRect(containerContext);
    if (containerRect == null) return;

    _scrollVelocity = _calculateScrollVelocity(dragRect, containerRect);

    if (_scrollVelocity != 0.0) {
      _startScrolling();
    } else {
      stopAutoScroll();
    }
  }

  Rect? _getContainerRect(BuildContext? containerContext) {
    RenderBox? renderBox;

    if (_containerKey?.currentContext != null) {
      renderBox =
          _containerKey!.currentContext!.findRenderObject() as RenderBox?;
    } else if (containerContext != null) {
      renderBox = containerContext.findRenderObject() as RenderBox?;
    }

    if (renderBox == null || !renderBox.hasSize) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  double _calculateScrollVelocity(Rect dragRect, Rect containerRect) {
    if (axis == Axis.horizontal) {
      return _calculateHorizontalVelocity(dragRect, containerRect);
    } else {
      return _calculateVerticalVelocity(dragRect, containerRect);
    }
  }

  double _calculateHorizontalVelocity(Rect dragRect, Rect containerRect) {
    final dragCenter = dragRect.center.dx;

    // Check if near left edge
    final leftEdge = containerRect.left + _edgeSize;
    if (dragCenter < leftEdge && scrollController.offset > 0) {
      // Calculate velocity based on distance from edge (closer = faster)
      final distance = leftEdge - dragCenter;
      final normalizedDistance = (distance / _edgeSize).clamp(0.0, 1.0);
      return -velocityScalar * normalizedDistance;
    }

    // Check if near right edge
    final rightEdge = containerRect.right - _edgeSize;
    if (dragCenter > rightEdge &&
        scrollController.offset < scrollController.position.maxScrollExtent) {
      final distance = dragCenter - rightEdge;
      final normalizedDistance = (distance / _edgeSize).clamp(0.0, 1.0);
      return velocityScalar * normalizedDistance;
    }

    return _minVelocity;
  }

  double _calculateVerticalVelocity(Rect dragRect, Rect containerRect) {
    final dragCenter = dragRect.center.dy;

    // Check if near top edge
    final topEdge = containerRect.top + _edgeSize;
    if (dragCenter < topEdge && scrollController.offset > 0) {
      final distance = topEdge - dragCenter;
      final normalizedDistance = (distance / _edgeSize).clamp(0.0, 1.0);
      return -velocityScalar * normalizedDistance;
    }

    // Check if near bottom edge
    final bottomEdge = containerRect.bottom - _edgeSize;
    if (dragCenter > bottomEdge &&
        scrollController.offset < scrollController.position.maxScrollExtent) {
      final distance = dragCenter - bottomEdge;
      final normalizedDistance = (distance / _edgeSize).clamp(0.0, 1.0);
      return velocityScalar * normalizedDistance;
    }

    return _minVelocity;
  }

  void _startScrolling() {
    if (_ticker != null && _ticker!.isActive) return;

    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    if (!scrollController.hasClients) {
      stopAutoScroll();
      return;
    }

    if (_scrollVelocity == 0.0) {
      stopAutoScroll();
      return;
    }

    final position = scrollController.position;
    final newOffset = (position.pixels + _scrollVelocity).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (newOffset != position.pixels) {
      scrollController.jumpTo(newOffset);
      onScrollViewScrolled?.call();
    } else {
      // Reached the edge, stop scrolling
      stopAutoScroll();
    }
  }

  /// Stops auto-scrolling.
  void stopAutoScroll() {
    _scrollVelocity = 0.0;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  /// Disposes resources.
  void dispose() {
    stopAutoScroll();
  }
}
