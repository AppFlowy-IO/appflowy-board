import 'package:flutter/widgets.dart';

import '../transitions.dart';

import 'drag_target.dart';

mixin ReorderFlexMixin {
  @protected
  Widget makeAppearingWidget(
    Widget child,
    AnimationController animationController,
    Size? draggingFeedbackSize,
    Axis direction,
  ) {
    final sizeFactor = animationController.withLinearCurve();
    if (null == draggingFeedbackSize) {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: sizeFactor,
        axis: direction,
        child: FadeTransition(
          opacity: sizeFactor,
          child: child,
        ),
      );
    } else {
      return ConstrainedBox(
        constraints: BoxConstraints.loose(draggingFeedbackSize),
        child: SizeTransition(
          sizeFactor: sizeFactor,
          axis: direction,
          child: FadeTransition(opacity: animationController, child: child),
        ),
      );
    }
  }

  @protected
  Widget makeDisappearingWidget(
    Widget child,
    AnimationController animationController,
    Size? draggingFeedbackSize,
    Axis direction,
  ) {
    final sizeFactor = animationController.withLinearCurve();
    if (null == draggingFeedbackSize) {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: sizeFactor,
        axis: direction,
        child: FadeTransition(
          opacity: sizeFactor,
          child: child,
        ),
      );
    } else {
      return ConstrainedBox(
        constraints: BoxConstraints.loose(draggingFeedbackSize),
        child: SizeTransition(
          sizeFactor: sizeFactor,
          axis: direction,
          child: FadeTransition(opacity: animationController, child: child),
        ),
      );
    }
  }
}

extension CurveAnimationController on AnimationController {
  Animation<double> withLinearCurve() {
    return withCurve(Curves.linear);
  }

  Animation<double> withCurve(Curve curve) {
    return CurvedAnimation(parent: this, curve: curve);
  }
}

class ReorderFlexNotifier extends DragTargetMovePlaceholderDelegate {
  Map<int, DragTargetEventNotifier> dragTargeEventNotifier = {};

  void updateDragTargetIndex(int index) {
    for (final notifier in dragTargeEventNotifier.values) {
      notifier.setDragTargetIndex(index);
    }
  }

  DragTargetEventNotifier _notifierFromIndex(int dragTargetIndex) {
    DragTargetEventNotifier? notifier = dragTargeEventNotifier[dragTargetIndex];
    if (notifier == null) {
      final newNotifier = DragTargetEventNotifier();
      dragTargeEventNotifier[dragTargetIndex] = newNotifier;
      notifier = newNotifier;
    }

    return notifier;
  }

  void dispose() {
    for (final notifier in dragTargeEventNotifier.values) {
      notifier.dispose();
    }
  }

  @override
  void registerPlaceholder(
    int dragTargetIndex,
    void Function(int dragTargetIndex) callback,
  ) {
    _notifierFromIndex(dragTargetIndex).addListener(() {
      callback.call(_notifierFromIndex(dragTargetIndex).currentDragTargetIndex);
    });
  }

  @override
  void unregisterPlaceholder(int dragTargetIndex) {
    dragTargeEventNotifier.remove(dragTargetIndex);
  }
}

class DragTargetEventNotifier extends ChangeNotifier {
  int currentDragTargetIndex = -1;

  void setDragTargetIndex(int index) {
    if (currentDragTargetIndex != index) {
      currentDragTargetIndex = index;
      notifyListeners();
    }
  }
}
