import 'package:flutter/material.dart';

typedef OnHeaderAddButtonClick = void Function();
typedef OnHeaderMoreButtonClick = void Function();

class AppFlowyGroupHeader extends StatelessWidget {
  const AppFlowyGroupHeader({
    super.key,
    this.height,
    this.icon,
    this.title,
    this.addIcon,
    this.moreIcon,
    this.margin = EdgeInsets.zero,
    this.onAddButtonClick,
    this.onMoreButtonClick,
  });

  final double? height;
  final Widget? icon;
  final Widget? title;
  final Widget? addIcon;
  final Widget? moreIcon;
  final EdgeInsets margin;
  final OnHeaderAddButtonClick? onAddButtonClick;
  final OnHeaderMoreButtonClick? onMoreButtonClick;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (icon != null) {
      children.add(icon!);
      children.add(_hSpace());
    }

    if (title != null) {
      children.add(title!);
      children.add(_hSpace());
    }

    if (moreIcon != null) {
      children.add(
        IconButton(
          onPressed: onMoreButtonClick,
          icon: moreIcon!,
          padding: const EdgeInsets.all(4),
        ),
      );
    }

    if (addIcon != null) {
      children.add(
        IconButton(
          onPressed: onAddButtonClick,
          icon: addIcon!,
          padding: const EdgeInsets.all(4),
        ),
      );
    }

    return Container(
      height: height,
      padding: margin,
      child: Row(children: children),
    );
  }

  Widget _hSpace() => const SizedBox(width: 6);
}
