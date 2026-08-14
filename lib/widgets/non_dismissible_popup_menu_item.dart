import 'package:flutter/material.dart';

class NonDismissiblePopupMenuItem<T> extends PopupMenuItem<T> {
  const NonDismissiblePopupMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.enabled = true,
    super.height = kMinInteractiveDimension,
    super.padding,
    super.textStyle,
    super.labelTextStyle,
    super.mouseCursor,
    super.child,
  });

  @override
  PopupMenuItemState<T, PopupMenuItem<T>> createState() =>
      _NonDismissiblePopupMenuItem<T, PopupMenuItem<T>>();
}

class _NonDismissiblePopupMenuItem<T, W extends PopupMenuItem<T>>
    extends PopupMenuItemState<T, W> {
  @override
  void handleTap() {
    widget.onTap?.call();
  }
}
