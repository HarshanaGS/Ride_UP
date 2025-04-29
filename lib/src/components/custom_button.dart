import 'package:flutter/material.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class CustomButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final String text;
  final VoidCallback funtion;
  final bool isLoading;
  final bool enabled;

  const CustomButton({
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    required this.text,
    required this.funtion,
    required this.isLoading,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 300,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: funtion,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            backgroundColor ?? AppColors.primaryColor,
          ),
          foregroundColor: WidgetStatePropertyAll(
            foregroundColor ?? AppColors.textColor,
          ),
          elevation: const WidgetStatePropertyAll(4),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  color: AppColors.textColor,
                  strokeWidth: 3,
                ),
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textColor,
                ),
              ),
      ),
    );
  }
}
