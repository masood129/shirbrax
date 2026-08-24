import 'package:flutter/foundation.dart';

/// Responsive breakpoints and layout helpers
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Is the current width a mobile layout?
  static bool isMobile(double width) => width < mobileBreakpoint;

  /// Is the current width a tablet layout?
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < desktopBreakpoint;

  /// Is the current width a desktop/web layout?
  static bool isDesktop(double width) => width >= desktopBreakpoint;

  /// Should we show a sidebar nav instead of bottom nav?
  static bool showSideNav(double width) => width >= mobileBreakpoint;

  /// Number of grid columns for media feed
  static int feedColumns(double width) {
    if (width >= desktopBreakpoint) return 3;
    if (width >= tabletBreakpoint) return 2;
    return 1;
  }

  /// Horizontal content padding based on width
  static double horizontalPadding(double width) {
    if (width >= desktopBreakpoint) return 120;
    if (width >= tabletBreakpoint) return 48;
    return 16;
  }

  /// Max content width (center on large screens)
  static double maxContentWidth(double width) {
    if (width >= desktopBreakpoint) return 900;
    return double.infinity;
  }

  /// Is running on web platform
  static bool get isWeb => kIsWeb;
}
