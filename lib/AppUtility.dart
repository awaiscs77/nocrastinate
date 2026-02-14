import 'package:flutter/material.dart';
import 'package:nocrastinate/ThemeManager.dart';

class KeyboardToolbar extends StatelessWidget {
  final int? currentLength;
  final int? maxLength;
  final VoidCallback? onDone;
  final String? leftText;
  final Widget? leftWidget;

  const KeyboardToolbar({
    Key? key,
    this.currentLength,
    this.maxLength,
    this.onDone,
    this.leftText,
    this.leftWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.cardBackgroundColor : Colors.grey[200],
        border: Border(
          top: BorderSide(
            color: context.primaryTextColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: leftWidget ??
                  (currentLength != null && maxLength != null
                      ? Text(
                    '$currentLength/$maxLength',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor.withOpacity(0.6),
                    ),
                  )
                      : (leftText != null
                      ? Text(
                    leftText!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor.withOpacity(0.6),
                    ),
                  )
                      : const SizedBox.shrink())),
            ),
          ),
          TextButton(
            onPressed: onDone ?? () {
              FocusScope.of(context).unfocus();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension method to easily add keyboard toolbar to any screen
extension KeyboardToolbarExtension on Widget {
  /// Wraps the widget with keyboard toolbar functionality
  Widget withKeyboardToolbar(
      BuildContext context, {
        int? currentLength,
        int? maxLength,
        VoidCallback? onDone,
        String? leftText,
        Widget? leftWidget,
      }) {
    return Column(
      children: [
        Expanded(child: this),
        if (MediaQuery.of(context).viewInsets.bottom > 0)
          KeyboardToolbar(
            currentLength: currentLength,
            maxLength: maxLength,
            onDone: onDone,
            leftText: leftText,
            leftWidget: leftWidget,
          ),
      ],
    );
  }
}

/// Helper mixin for screens that need keyboard toolbar
/// Add this to your State class: with KeyboardToolbarMixin
mixin KeyboardToolbarMixin<T extends StatefulWidget> on State<T> {
  /// Wrap your body content with this method
  Widget buildWithKeyboardToolbar({
    required Widget child,
    int? currentLength,
    int? maxLength,
    VoidCallback? onDone,
    String? leftText,
    Widget? leftWidget,
  }) {
    return Column(
      children: [
        Expanded(child: child),
        if (MediaQuery.of(context).viewInsets.bottom > 0)
          KeyboardToolbar(
            currentLength: currentLength,
            maxLength: maxLength,
            onDone: onDone,
            leftText: leftText,
            leftWidget: leftWidget,
          ),
      ],
    );
  }
}