import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_alert_dialog.dart';

Future<void>? customShowDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String confirmText,
  VoidCallback? onConfirm,
  String? cancelText,
  VoidCallback? onCancel,
  Color? confirmTextColor,
  Color? cancelTextColor,
}) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return CustomAlertDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        onCancel: onCancel,
        confirmText: confirmText,
        onConfirm: onConfirm!,
        confirmTextColor: confirmTextColor,
        cancelTextColor: cancelTextColor,
      );
    },
  );
}
