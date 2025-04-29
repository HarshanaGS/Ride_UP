import 'package:flutter/material.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? cancelText;
  final VoidCallback? onCancel;
  final String confirmText;
  final VoidCallback onConfirm;
  final bool barrierDismissible;
  final Color? confirmTextColor;
  final Color? cancelTextColor;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    this.onCancel,
    required this.confirmText,
    required this.onConfirm,
    this.barrierDismissible = true,
    required this.confirmTextColor,
    required this.cancelTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secundaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textColor),
      ),
      content: content,
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: Text(
              cancelText!,
              style: TextStyle(
                color: cancelTextColor ?? AppColors.textColor,
              ),
            ),
          ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            confirmText,
            style: TextStyle(
              color: confirmTextColor ?? AppColors.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
