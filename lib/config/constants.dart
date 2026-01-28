import 'package:flutter/material.dart';

/// ==================== RESPONSIVE BREAKPOINTS ====================
class AppBreakpoints {
  // Device width breakpoints for responsive design
  static const double mobile = 480.0;      // Small phones (< 480px)
  static const double tablet = 768.0;      // Tablets (768px - 1024px)
  static const double desktop = 1024.0;    // Desktop (> 1024px)
  static const double extraLarge = 1440.0; // Large screens (> 1440px)
}

/// Responsive helper class for screen-aware values
class ResponsiveValue {
  final double mobile;
  final double tablet;
  final double? desktop;
  final double? extraLarge;

  ResponsiveValue({
    required this.mobile,
    required this.tablet,
    this.desktop,
    this.extraLarge,
  });

  /// Get value based on screen width
  double getValue(double screenWidth) {
    if (screenWidth >= (extraLarge ?? 1440)) {
      return extraLarge ?? desktop ?? tablet;
    } else if (screenWidth >= (desktop ?? 1024)) {
      return desktop ?? tablet;
    } else if (screenWidth >= AppBreakpoints.tablet) {
      return tablet;
    }
    return mobile;
  }
}

/// Device type detection
enum DeviceType { mobile, tablet, desktop, extraLarge }

/// Extension for easy device type detection
extension ScreenSize on MediaQueryData {
  DeviceType get deviceType {
    final width = size.width;
    if (width >= AppBreakpoints.extraLarge) {
      return DeviceType.extraLarge;
    } else if (width >= AppBreakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width >= AppBreakpoints.tablet) {
      return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }

  bool get isMobile => size.width < AppBreakpoints.tablet;
  bool get isTablet =>
      size.width >= AppBreakpoints.tablet &&
      size.width < AppBreakpoints.desktop;
  bool get isDesktop => size.width >= AppBreakpoints.desktop;
  bool get isLargeScreen => size.width >= AppBreakpoints.extraLarge;
}

/// Responsive padding based on screen size
class AppResponsivePadding {
  final MediaQueryData mediaQuery;

  AppResponsivePadding(this.mediaQuery);

  /// Horizontal padding - adapts to screen size
  EdgeInsets get horizontalPadding {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.desktop) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else if (width >= AppBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    return const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  }

  /// Vertical padding - adapts to screen size
  EdgeInsets get verticalPadding {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.desktop) {
      return const EdgeInsets.symmetric(vertical: 32);
    } else if (width >= AppBreakpoints.tablet) {
      return const EdgeInsets.symmetric(vertical: 28);
    }
    return const EdgeInsets.symmetric(vertical: AppSpacing.xxl);
  }

  /// Both horizontal and vertical padding
  EdgeInsets get allPadding {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.desktop) {
      return const EdgeInsets.all(32);
    } else if (width >= AppBreakpoints.tablet) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(AppSpacing.lg);
  }

  /// Responsive gap between sections
  double get sectionGap {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.desktop) {
      return 40;
    } else if (width >= AppBreakpoints.tablet) {
      return 32;
    }
    return AppSpacing.xxxl;
  }

  /// Responsive button height
  double get buttonHeight {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.tablet) {
      return 48;
    }
    return 56;
  }

  /// Responsive icon size
  double get iconSize {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.desktop) {
      return 32;
    } else if (width >= AppBreakpoints.tablet) {
      return 28;
    }
    return 24;
  }

  /// Responsive logo size
  double get logoSize {
    final width = mediaQuery.size.width;
    if (width >= AppBreakpoints.desktop) {
      return 160;
    } else if (width >= AppBreakpoints.tablet) {
      return 140;
    }
    return 120;
  }
}

/// App Color Palette
class AppColors {
  // Primary Colors
  static const Color primary = Colors.deepPurple;
  static const Color primaryLight = Color(0xFFEDE7F6);
  static const Color primaryDark = Color(0xFF512DA8);

  // Secondary Colors
  static const Color secondary = Colors.blue;
  static const Color secondaryLight = Color(0xFFE3F2FD);
  static const Color secondaryDark = Color(0xFF1565C0);

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color greyLight = Color(0xFFFAFAFA);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Background & Surface Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
}

/// App Spacing Constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

/// App Border Radius
class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double circle = 50.0;
}

/// App Typography Styles
class AppText {
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  // Subheadings
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.grey,
  );

  // Body Text
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.grey,
  );

  // Label & Button Text
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.grey,
  );
}

/// App Shadows
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x2E000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow xl = BoxShadow(
    color: Color(0x3D000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static final List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> elevatedShadow = [
    const BoxShadow(
      color: Color(0x2E000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// App Gradients
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleToBlue = LinearGradient(
    colors: [Colors.deepPurple, Colors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueToTeal = LinearGradient(
    colors: [Colors.blue, Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleToBlack = LinearGradient(
    colors: [Colors.deepPurple, Colors.black54],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
