import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_board/appflowy_board.dart';
import 'package:appflowy_board/src/utils/log.dart';

import '../transitions.dart';

abstract class DragTargetData {
  int get draggingIndex;
}

abstract class ReorderFlexDraggableTargetBuilder {
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
    DragTargetWillAccepted<T> onWillAccept,
    AnimationController insertAnimationController,
    AnimationController deleteAnimationController,
  );
}

typedef DragTargetWillAccepted<T extends DragTargetData> = bool Function(
  T dragTargetData,
);

typedef DragTargetOnStarted = void Function(Widget, int, Size?);

typedef DragTargetOnMove<T extends DragTargetData> = void Function(
  T dragTargetData,
  Offset offset,
);

typedef DragTargetOnEnded<T extends DragTargetData> = void Function(
  T dragTargetData,
);

/// [ReorderDragTarget] is a [DragTarget] that carries the index information of
/// the child. You could check out this link for more information.
///
/// The size of the [ReorderDragTarget] will become zero when it start dragging.
///
class ReorderDragTarget<T extends DragTargetData> extends StatefulWidget {
  const ReorderDragTarget({
    super.key,
    required this.child,
    required this.indexGlobalKey,
    required this.dragTargetData,
    required this.onDragStarted,
    required this.onDragMoved,
    required this.onDragEnded,
    required this.onWillAcceptWithDetails,
    this.onAccceptWithDetails,
    required this.insertAnimationController,
    required this.deleteAnimationController,
    required this.useMoveAnimation,
    required this.draggable,
    this.onLeave,
    this.draggableTargetBuilder,
    this.draggingOpacity = 0.3,
    this.dragDirection,
  });

  final Widget child;
  final GlobalObjectKey indexGlobalKey;
  final T dragTargetData;

  /// Called when dragTarget is being dragging.
  final DragTargetOnStarted onDragStarted;

  final DragTargetOnMove<T> onDragMoved;
  final DragTargetOnEnded<T> onDragEnded;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// [toAccept] represents the dragTarget index, which is the value passed in
  /// when creating the [ReorderDragTarget].
  final DragTargetWillAccepted<T> onWillAcceptWithDetails;

  /// Called when an acceptable piece of data was dropped over this drag target.
  final void Function(T dragTargetData)? onAccceptWithDetails;

  final AnimationController insertAnimationController;
  final AnimationController deleteAnimationController;
  final bool useMoveAnimation;
  final IsDraggable draggable;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final void Function(T dragTargetData)? onLeave;

  final ReorderFlexDraggableTargetBuilder? draggableTargetBuilder;
  final double draggingOpacity;
  final Axis? dragDirection;

  @override
  State<ReorderDragTarget<T>> createState() => _ReorderDragTargetState<T>();
}

class _ReorderDragTargetState<T extends DragTargetData>
    extends State<ReorderDragTarget<T>> {
  /// the dragTarget's size
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    Widget dragTarget = DragTarget<T>(
      builder: _buildDraggableWidget,
      onWillAcceptWithDetails: (details) =>
          widget.onWillAcceptWithDetails(details.data),
      onAcceptWithDetails: (details) =>
          widget.onAccceptWithDetails?.call(details.data),
      onMove: (detail) {
        // // Expand the scroll view horizontally when the dragging is near the edge of the scroll view.
        // // It is used to move card to the other group.
        // final scrollController = widget.scrollController;
        // final maxScrollExtent = scrollController.position.maxScrollExtent;
        // final minScrollExtent = scrollController.position.minScrollExtent;
        // const expandDistance = 20;

        // if (detail.offset.dx >
        //     MediaQuery.of(context).size.width - widget.groupWidth) {
        //   final newPosition =
        //       scrollController.offset + expandDistance > maxScrollExtent
        //           ? maxScrollExtent
        //           : scrollController.offset + expandDistance;
        //   widget.scrollController.jumpTo(newPosition);
        // }
        // if (detail.offset.dx < 20) {
        //   final newPosition =
        //       scrollController.offset - expandDistance < minScrollExtent
        //           ? minScrollExtent
        //           : scrollController.offset - expandDistance;
        //   widget.scrollController.jumpTo(newPosition);
        // }

        widget.onDragMoved(detail.data, detail.offset);
      },
      onLeave: (dragTargetData) {
        assert(dragTargetData != null);
        if (dragTargetData != null) {
          widget.onLeave?.call(dragTargetData);
        }
      },
    );

    dragTarget = KeyedSubtree(key: widget.indexGlobalKey, child: dragTarget);
    return dragTarget;
  }

  Widget _buildDraggableWidget(
    BuildContext context,
    List<T?> acceptedCandidates,
    List<dynamic> rejectedCandidates,
  ) {
    final feedbackBuilder = Builder(
      builder: (BuildContext context) {
        final BoxConstraints contentSizeConstraints =
            BoxConstraints.loose(_draggingFeedbackSize!);
        return _buildDraggableFeedback(
          context,
          contentSizeConstraints,
          widget.child,
        );
      },
    );

    final draggableWidget = widget.draggableTargetBuilder?.build(
      context,
      widget.child,
      widget.onDragStarted,
      widget.onDragEnded,
      widget.onWillAcceptWithDetails,
      widget.insertAnimationController,
      widget.deleteAnimationController,
    );

    if (draggableWidget == null) {
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        // On mobile, we use [LongPressDraggable] to avoid conflicts with scrolling screen behavior. The configuration of [LongPressDraggable] is the same as [Draggable].
        return LongPressDraggable<DragTargetData>(
          axis: widget.dragDirection,
          maxSimultaneousDrags: widget.draggable ? 1 : 0,
          data: widget.dragTargetData,
          ignoringFeedbackSemantics: false,
          feedback: feedbackBuilder,
          childWhenDragging: IgnorePointerWidget(
            useIntrinsicSize: !widget.useMoveAnimation,
            opacity: widget.draggingOpacity,
            child: widget.child,
          ),
          onDragStarted: () {
            _draggingFeedbackSize = widget.indexGlobalKey.currentContext?.size;
            widget.onDragStarted(
              widget.child,
              widget.dragTargetData.draggingIndex,
              _draggingFeedbackSize,
            );
          },

          /// When the drag ends inside a DragTarget widget, the drag
          /// succeeds, and we reorder the widget into position appropriately.
          onDragCompleted: () => widget.onDragEnded(widget.dragTargetData),

          /// When the drag does not end inside a DragTarget widget, the
          /// drag fails, but we still reorder the widget to the last position it
          /// had been dragged to.
          onDraggableCanceled: (_, __) =>
              widget.onDragEnded(widget.dragTargetData),
          child: widget.child,
        );
      }
      return Draggable<DragTargetData>(
        axis: widget.dragDirection,
        maxSimultaneousDrags: widget.draggable ? 1 : 0,
        data: widget.dragTargetData,
        ignoringFeedbackSemantics: false,
        feedback: feedbackBuilder,
        childWhenDragging: IgnorePointerWidget(
          useIntrinsicSize: !widget.useMoveAnimation,
          opacity: widget.draggingOpacity,
          child: widget.child,
        ),
        onDragStarted: () {
          _draggingFeedbackSize = widget.indexGlobalKey.currentContext?.size;
          widget.onDragStarted(
            widget.child,
            widget.dragTargetData.draggingIndex,
            _draggingFeedbackSize,
          );
        },

        /// When the drag ends inside a DragTarget widget, the drag
        /// succeeds, and we reorder the widget into position appropriately.
        onDragCompleted: () => widget.onDragEnded(widget.dragTargetData),

        /// When the drag does not end inside a DragTarget widget, the
        /// drag fails, but we still reorder the widget to the last position it
        /// had been dragged to.
        onDraggableCanceled: (_, __) =>
            widget.onDragEnded(widget.dragTargetData),
        child: widget.child,
      );
    }

    return draggableWidget;
  }

  Widget _buildDraggableFeedback(
    BuildContext context,
    BoxConstraints constraints,
    Widget child,
  ) {
    return Transform(
      transform: Matrix4.rotationZ(0),
      alignment: FractionalOffset.topLeft,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        clipBehavior: Clip.hardEdge,
        child: ConstrainedBox(
          constraints: constraints,
          child: Opacity(opacity: widget.draggingOpacity, child: child),
        ),
      ),
    );
  }
}

class DragTargetAnimation {
  DragTargetAnimation({
    required this.reorderAnimationDuration,
    required void Function(AnimationStatus) entranceAnimateStatusChanged,
    required TickerProvider vsync,
  }) {
    entranceController = AnimationController(
      value: 1.0,
      vsync: vsync,
      duration: reorderAnimationDuration,
    );
    entranceController.addStatusListener(entranceAnimateStatusChanged);

    phantomController = AnimationController(
      value: 0,
      vsync: vsync,
      duration: reorderAnimationDuration,
    );

    insertController = AnimationController(
      value: 0.0,
      vsync: vsync,
      duration: const Duration(milliseconds: 100),
    );

    deleteController = AnimationController(
      value: 0.0,
      vsync: vsync,
      duration: const Duration(milliseconds: 1),
    );
  }

  // How long an animation to reorder an element in the list takes.
  final Duration reorderAnimationDuration;

  // This controls the entrance of the dragging widget into a new place.
  late AnimationController entranceController;

  // This controls the 'phantom' of the dragging widget, which is left behind
  // where the widget used to be.
  late AnimationController phantomController;

  // Uses to simulate the insert animation when card was moved from on group to
  // another group. Check out the [FakeDragTarget].
  late AnimationController insertController;

  // Used to remove the phantom
  late AnimationController deleteController;

  void startDragging() => entranceController.value = 1.0;

  void animateToNext() {
    phantomController.reverse(from: 1.0);
    entranceController.forward(from: 0.0);
  }

  void reverseAnimation() {
    phantomController.reverse(from: 0.1);
    entranceController.reverse(from: 0.0);
  }

  void dispose() {
    entranceController.dispose();
    phantomController.dispose();
    insertController.dispose();
    deleteController.dispose();
  }
}

class IgnorePointerWidget extends StatelessWidget {
  const IgnorePointerWidget({
    super.key,
    required this.child,
    required this.opacity,
    this.useIntrinsicSize = false,
  });

  final Widget? child;
  final double opacity;
  final bool useIntrinsicSize;

  @override
  Widget build(BuildContext context) {
    final sizedChild = useIntrinsicSize
        ? child
        : SizedBox(width: 0.0, height: 0.0, child: child);

    return IgnorePointer(
      child: Opacity(
        opacity: useIntrinsicSize ? opacity : 0.0,
        child: sizedChild,
      ),
    );
  }
}

class AbsorbPointerWidget extends StatelessWidget {
  const AbsorbPointerWidget({
    super.key,
    required this.child,
    required this.opacity,
    this.useIntrinsicSize = false,
  });

  final Widget? child;
  final double opacity;
  final bool useIntrinsicSize;

  @override
  Widget build(BuildContext context) {
    final sizedChild = useIntrinsicSize
        ? child
        : SizedBox(width: 0.0, height: 0.0, child: child);

    return AbsorbPointer(
      child: Opacity(
        opacity: useIntrinsicSize ? opacity : 0.0,
        child: sizedChild,
      ),
    );
  }
}

class PhantomWidget extends StatelessWidget {
  const PhantomWidget({super.key, this.child, this.opacity = 1.0});

  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: opacity, child: child);
  }
}

abstract class DragTargetMovePlaceholderDelegate {
  void registerPlaceholder(
    int dragTargetIndex,
    void Function(int currentDragTargetIndex) callback,
  );

  void unregisterPlaceholder(int dragTargetIndex);
}

abstract class FakeDragTargetEventTrigger {
  void fakeOnDragStart(void Function(int?) callback);
  void fakeOnDragEnded(VoidCallback callback);
}

abstract class FakeDragTargetEventData {
  Size? get feedbackSize;
  int get index;
  DragTargetData get dragTargetData;
}

class FakeDragTarget<T extends DragTargetData> extends StatefulWidget {
  const FakeDragTarget({
    super.key,
    required this.eventTrigger,
    required this.eventData,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onWillAccept,
    required this.insertAnimationController,
    required this.deleteAnimationController,
    required this.child,
  });

  final FakeDragTargetEventTrigger eventTrigger;
  final FakeDragTargetEventData eventData;
  final DragTargetOnStarted onDragStarted;
  final DragTargetOnEnded<T> onDragEnded;
  final DragTargetWillAccepted<T> onWillAccept;
  final AnimationController insertAnimationController;
  final AnimationController deleteAnimationController;
  final Widget child;

  @override
  State<FakeDragTarget<T>> createState() => _FakeDragTargetState<T>();
}

class _FakeDragTargetState<T extends DragTargetData>
    extends State<FakeDragTarget<T>>
    with TickerProviderStateMixin<FakeDragTarget<T>> {
  bool simulateDragging = false;

  @override
  void initState() {
    super.initState();

    widget.insertAnimationController.addStatusListener(
      _onInsertedAnimationStatusChanged,
    );

    /// Start insert animation
    widget.insertAnimationController.forward(from: 0.0);

    widget.eventTrigger.fakeOnDragEnded(() {
      Log.trace("[$FakeDragTarget] on drag end");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDragEnded(widget.eventData.dragTargetData as T);
      });
    });
  }

  @override
  void dispose() {
    widget.insertAnimationController
        .removeStatusListener(_onInsertedAnimationStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (simulateDragging) {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: widget.deleteAnimationController,
        child: AbsorbPointerWidget(
          opacity: 0.3,
          child: widget.child,
        ),
      );
    } else {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: widget.insertAnimationController,
        child: AbsorbPointerWidget(
          useIntrinsicSize: true,
          opacity: 0.3,
          child: widget.child,
        ),
      );
    }
  }

  void _onInsertedAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (widget.onWillAccept(widget.eventData.dragTargetData as T)) {
          Log.trace("[$FakeDragTarget] on drag start");
          simulateDragging = true;
          widget.deleteAnimationController.reverse(from: 1.0);
          widget.onDragStarted(
            widget.child,
            widget.eventData.index,
            widget.eventData.feedbackSize,
          );
        } else {
          Log.trace("[$FakeDragTarget] cancel start drag");
        }
      });
    });
  }
}
