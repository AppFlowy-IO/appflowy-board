import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SizeTransitionWithIntrinsicSize extends SingleChildRenderObjectWidget {
  /// Creates a size transition with its intrinsic width/height taking [sizeFactor]
  /// into account.
  ///
  /// The [axis] argument defaults to [Axis.vertical].
  /// The [axisAlignment] defaults to 0.0, which centers the child along the
  ///  main axis during the transition.
  SizeTransitionWithIntrinsicSize({
    super.key,
    this.axis = Axis.vertical,
    required this.sizeFactor,
    double axisAlignment = 0.0,
    Widget? child,
  }) : super(
          child: SizeTransition(
            axis: axis,
            sizeFactor: sizeFactor,
            axisAlignment: axisAlignment,
            child: child,
          ),
        );

  final Axis axis;
  final Animation<double> sizeFactor;

  @override
  RenderSizeTransitionWithIntrinsicSize createRenderObject(
    BuildContext context,
  ) {
    return RenderSizeTransitionWithIntrinsicSize(
      axis: axis,
      sizeFactor: sizeFactor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizeTransitionWithIntrinsicSize renderObject,
  ) {
    renderObject
      ..axis = axis
      ..sizeFactor = sizeFactor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Axis>('axis', axis));
    properties
        .add(DiagnosticsProperty<Animation<double>>('sizeFactor', sizeFactor));
  }
}

class RenderSizeTransitionWithIntrinsicSize extends RenderProxyBox {
  RenderSizeTransitionWithIntrinsicSize({
    required this.sizeFactor,
    this.axis = Axis.vertical,
    RenderBox? child,
  }) : super(child);

  Animation<double> sizeFactor;
  Axis axis;

  @override
  double computeMinIntrinsicWidth(double height) {
    final child = this.child;
    if (child != null) {
      final childWidth = child.getMinIntrinsicWidth(height);
      return axis == Axis.horizontal
          ? childWidth * sizeFactor.value
          : childWidth;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final child = this.child;
    if (child != null) {
      final childWidth = child.getMaxIntrinsicWidth(height);
      return axis == Axis.horizontal
          ? childWidth * sizeFactor.value
          : childWidth;
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final child = this.child;
    if (child != null) {
      final childHeight = child.getMinIntrinsicHeight(width);
      return axis == Axis.vertical
          ? childHeight * sizeFactor.value
          : childHeight;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final child = this.child;
    if (child != null) {
      final childHeight = child.getMaxIntrinsicHeight(width);
      return axis == Axis.vertical
          ? childHeight * sizeFactor.value
          : childHeight;
    }
    return 0.0;
  }
}
