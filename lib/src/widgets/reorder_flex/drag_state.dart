import 'package:flutter/material.dart';

import '../../utils/log.dart';

import 'drag_target.dart';
import 'reorder_flex.dart';

/// [FlexDragTargetData] is used to store the custom dragging data.
///
/// * [draggingIndex] the index of the dragTarget that is being dragged.
/// * [draggingWidget] the widget of the dragTarget that is being dragged.
/// * [reorderFlexId] the id of the [ReorderFlex]
/// * [reorderFlexItem] the item of the [ReorderFlex]
///
class FlexDragTargetData extends DragTargetData {
  FlexDragTargetData({
    required this.dragTargetId,
    required this.draggingIndex,
    required this.reorderFlexId,
    required this.reorderFlexItem,
    required this.dragTargetIndexKey,
    required DraggingState draggingState,
  }) : _draggingState = draggingState;

  final String dragTargetId;

  /// The index of the dragging target in the boardList.
  @override
  final int draggingIndex;

  final String reorderFlexId;
  final ReoderFlexItem reorderFlexItem;
  final GlobalObjectKey dragTargetIndexKey;
  final DraggingState _draggingState;

  Offset dragTargetOffset = Offset.zero;

  Widget? get draggingWidget => _draggingState.draggingWidget;
  Size? get feedbackSize => _draggingState.feedbackSize;
  bool get isDragging => _draggingState.isDragging();

  @override
  String toString() =>
      'ReorderFlexId: $reorderFlexId, dragTargetId: $dragTargetId';

  bool isOverlapWithWidgets(List<GlobalObjectKey> widgetKeys) {
    final renderBox = dragTargetIndexKey.currentContext?.findRenderObject();
    if (renderBox == null) return false;
    if (renderBox is! RenderBox) return false;
    final size = feedbackSize ?? Size.zero;

    final Rect dragTargetRect = renderBox.localToGlobal(Offset.zero) & size;
    for (final widgetKey in widgetKeys) {
      final renderObject = widgetKey.currentContext?.findRenderObject();
      if (renderObject != null && renderObject is RenderBox) {
        final Rect widgetRect =
            renderObject.localToGlobal(Offset.zero) & renderObject.size;
        return dragTargetRect.overlaps(widgetRect);
      }
    }

    return false;
  }
}

abstract class DraggingStateStorage {
  void insertState(String reorderFlexId, DraggingState state);
  void removeState(String reorderFlexId);
  DraggingState? readState(String reorderFlexId);
}

class DraggingState {
  DraggingState(this.reorderFlexId);

  final String reorderFlexId;

  /// The member of widget.children currently being dragged.
  Widget? _draggingWidget;

  Widget? get draggingWidget => _draggingWidget;

  /// The last computed size of the feedback widget being dragged.
  Size? feedbackSize = Size.zero;

  GlobalObjectKey? draggingKey;

  /// The location that the dragging widget occupied before it started to drag.
  int dragStartIndex = -1;

  /// The index that the dragging widget most recently left.
  /// This is used to show an animation of the widget's position.
  int phantomIndex = -1;

  /// The index that the dragging widget currently occupies.
  int currentIndex = -1;

  /// The widget to move the dragging widget too after the current index.
  int nextIndex = -1;

  /// Whether or not we are currently scrolling this view to show a widget.
  bool scrolling = false;

  /// The additional margin to place around a computed drop area.
  static const double _dropAreaMargin = 0.0;

  Size get dropAreaSize {
    if (feedbackSize == null) {
      return Size.zero;
    }
    return feedbackSize! + const Offset(_dropAreaMargin, _dropAreaMargin);
  }

  void startDragging(
    Widget draggingWidget,
    int draggingWidgetIndex,
    Size? draggingWidgetSize,
  ) {
    ///
    assert(draggingWidgetIndex >= 0);

    _draggingWidget = draggingWidget;
    phantomIndex = draggingWidgetIndex;
    dragStartIndex = draggingWidgetIndex;
    currentIndex = draggingWidgetIndex;
    feedbackSize = draggingWidgetSize;
  }

  void endDragging() {
    dragStartIndex = -1;
    phantomIndex = -1;
    currentIndex = -1;
    nextIndex = -1;
    _draggingWidget = null;
  }

  /// When the phantomIndex and currentIndex are the same, it means the dragging
  /// widget did move to the destination location.
  void removePhantom() => phantomIndex = currentIndex;

  /// The dragging widget overlaps with the phantom widget.
  bool isOverlapWithPhantom() => currentIndex != phantomIndex;

  bool isPhantomAboveDragTarget() => currentIndex > phantomIndex;

  bool isPhantomBelowDragTarget() => currentIndex < phantomIndex;

  bool didDragTargetMoveToNext() => currentIndex == nextIndex;

  /// Set the currentIndex to nextIndex
  void moveDragTargetToNext() {
    Log.debug('$reorderFlexId updateCurrentIndex: $nextIndex');
    currentIndex = nextIndex;
  }

  void updateNextIndex(int index) {
    Log.debug('$reorderFlexId updateNextIndex: $index');
    nextIndex = index;
  }

  void setStartDraggingIndex(int index) {
    Log.debug('$reorderFlexId setDragIndex: $index');
    dragStartIndex = index;
    phantomIndex = index;
    currentIndex = index;
    nextIndex = index;
  }

  bool isNotDragging() => dragStartIndex == -1;

  bool isDragging() => !isNotDragging();

  /// When the _dragStartIndex less than the _currentIndex, it means the
  /// dragTarget is going down to the end of the list.
  bool isDragTargetMovingDown() => dragStartIndex < currentIndex;

  /// The index represents the widget original index of the list.
  int calculateShiftedIndex(int index) {
    int shiftedIndex = index;
    if (index == dragStartIndex) {
      shiftedIndex = phantomIndex;
    } else if (index > dragStartIndex && index <= phantomIndex) {
      /// phantom move up
      shiftedIndex--;
    } else if (index < dragStartIndex && index >= phantomIndex) {
      /// phantom move down
      shiftedIndex++;
    }
    return shiftedIndex;
  }

  @override
  String toString() =>
      'DragStartIndex: $dragStartIndex, PhantomIndex: $phantomIndex, CurrentIndex: $currentIndex, NextIndex: $nextIndex';
}
