import 'package:flutter/material.dart';

typedef OnFooterAddButtonClick = void Function();

class AppFlowyGroupFooter extends StatelessWidget {
  final double? height;
  final Widget? icon;
  final Widget? title;
  final EdgeInsets margin;
  final OnFooterAddButtonClick? onAddButtonClick;

  const AppFlowyGroupFooter({
    super.key,
    this.icon,
    this.title,
    this.margin = const EdgeInsets.symmetric(horizontal: 12),
    this.height,
    this.onAddButtonClick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAddButtonClick,
      child: Container(
        height: height,
        padding: margin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
