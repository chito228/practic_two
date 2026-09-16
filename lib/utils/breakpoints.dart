import 'package:flutter/material.dart';

/// Точки перехода для адаптивной вёрстки.
class Breakpoints {
  static const double mobile = 360;
  static const double tablet = 768;
  static const double desktop = 1280;
  static const double wide = 1920;

  /// Максимальная ширина контента на широких экранах.
  static const double maxContentWidth = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tablet && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= wide;
}
