import 'package:flutter/material.dart';

class AppFlowyGroupCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsets margin;
  final BoxConstraints boxConstraints;
  final BoxDecoration decoration;

  const AppFlowyGroupCard({
    super.key,
    this.child,
    this.margin = const EdgeInsets.all(4),
    this.decoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.zero,
    ),
    this.boxConstraints = const BoxConstraints(minHeight: 40),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: margin,
      constraints: boxConstraints,
      decoration: decoration,
      child: child,
    );
  }
}
