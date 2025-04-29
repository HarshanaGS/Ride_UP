import 'dart:async';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class CustomOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isOverlayVisible = false;

  static void show(
    BuildContext context, {
    required String texto,
    Duration duration = const Duration(seconds: 3),
    double top = 0.18,
    double left = 80,
    double right = 20,
  }) {
    if (_isOverlayVisible) return;

    _isOverlayVisible = true;
    _overlayEntry = _criarOverlayEntry(context, texto, top, left, right);
    Overlay.of(context).insert(_overlayEntry!);

    Timer(duration, _removerOverlay);
  }

  static OverlayEntry _criarOverlayEntry(
    BuildContext context,
    String texto,
    double top,
    double left,
    double right,
  ) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: left,
        right: right,
        child: GestureDetector(
          onTap: _removerOverlay,
          behavior: HitTestBehavior.translucent,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secundaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  texto,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _removerOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isOverlayVisible = false;
    }
  }
}
