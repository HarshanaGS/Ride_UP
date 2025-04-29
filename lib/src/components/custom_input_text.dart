import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class CustomInputText extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hintText;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onSuffixIconPressed;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final int? maxLength;
  final Widget? suffixIcon;
  final Widget? preffixIcon;
  final Function(String)? onChanged;
  final bool isLoading;
  final bool enable;
  final bool readOnly;
  final OutlineInputBorder? border;
  final OutlineInputBorder? focusedBorder;
  final Color? cursorColor;
  final TextStyle? hintStyle;
  final Color? textColor;
  final Color? iconColor;
  final String? errorText;
  final FocusNode? focusNode;

  const CustomInputText({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    this.isPassword = false,
    this.obscureText = false,
    this.onSuffixIconPressed,
    this.validator,
    this.maxLength,
    this.suffixIcon,
    this.preffixIcon,
    this.onChanged,
    this.isLoading = false,
    this.enable = true,
    this.readOnly = false,
    super.key,
    this.border,
    this.focusedBorder,
    this.cursorColor,
    this.hintStyle,
    this.textColor,
    this.onTap,
    this.iconColor,
    this.errorText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      enabled: isLoading ? false : enable,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      cursorColor: cursorColor ?? AppColors.textColor,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged!(value);
        }
      },
      focusNode: focusNode,
      onTap: onTap,
      style: TextStyle(color: textColor ?? AppColors.textColor),
      readOnly: readOnly,
      decoration: InputDecoration(
        errorText: errorText,
        hintText: hintText,
        hintStyle: hintStyle ??
            TextStyle(
              color: AppColors.secundarytextColor,
              fontSize: 15,
            ),
        border: border ??
            const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.black12),
            ),
        focusedBorder: focusedBorder ??
            OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textColor),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
        counterText: '',
        prefixIcon: preffixIcon,
        suffixIcon: isPassword
            ? IconButton(
                color: AppColors.textColor,
                onPressed: onSuffixIconPressed,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: iconColor,
                ),
              )
            : suffixIcon,
      ),
    );
  }
}
