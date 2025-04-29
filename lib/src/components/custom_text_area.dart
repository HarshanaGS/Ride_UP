import 'package:flutter/material.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class CustomTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int? maxLength;
  final Function(String)? onChanged;
  final bool isLoading;
  final bool enable;
  final bool readOnly;
  final OutlineInputBorder? border;
  final OutlineInputBorder? focusedBorder;
  final Color? cursorColor;
  final TextStyle? hintStyle;
  final Color? textColor;
  final Color? counterTextColor;
  final int maxLines;
  final int? minLines;

  const CustomTextArea({
    required this.controller,
    required this.hintText,
    this.validator,
    this.maxLength,
    this.onChanged,
    this.isLoading = false,
    this.enable = true,
    this.readOnly = false,
    this.border,
    this.focusedBorder,
    this.cursorColor,
    this.hintStyle,
    this.textColor,
    this.maxLines = 5,
    this.minLines,
    super.key,
    this.counterTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      enabled: isLoading ? false : enable,
      cursorColor: cursorColor ?? Colors.black54,
      onChanged: onChanged,
      style: TextStyle(color: textColor ?? Colors.black54),
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines ?? 3,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle ?? Theme.of(context).textTheme.titleSmall,
        border: border ??
            const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.black12),
            ),
        focusedBorder: focusedBorder ??
            const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
        counterStyle: TextStyle(color: counterTextColor ?? AppColors.textColor),
      ),
    );
  }
}
