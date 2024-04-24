import 'package:flutter/material.dart';

typedef OnFooterAddButtonClick = void Function();

class AppFlowyGroupFooter extends StatelessWidget {
  const AppFlowyGroupFooter({
    super.key,
    this.icon,
    this.title,
    this.margin = const EdgeInsets.symmetric(horizontal: 12),
    this.height,
    this.onAddButtonClick,
  });

  final Widget? icon;
  final Widget? title;
  final EdgeInsets margin;
  final double? height;
  final OnFooterAddButtonClick? onAddButtonClick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAddButtonClick,
      child: Container(
        height: height,
        padding: margin,
        child: Row(
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            if (title != null) title!,
          ],
        ),
      ),
    );
  }
}
