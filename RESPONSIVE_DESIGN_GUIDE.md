# Responsive Design Guide

## Overview

This guide explains the responsive design system implemented in the Cryptography Visualizer application. The system ensures that the UI adapts seamlessly to different screen sizes and orientations (mobile, tablet, desktop).

---

## Device Breakpoints

The application defines four device categories based on screen width:

| Device Type | Screen Width Range | Use Case |
|-------------|------------------|----------|
| **Mobile** | < 480px | Phones (Portrait/Landscape) |
| **Tablet** | 480px - 768px | Small tablets, large phones |
| **Desktop** | 768px - 1024px | Tablets, small laptops |
| **Extra Large** | ≥ 1024px | Large screens, TVs |

### AppBreakpoints Class

Located in `lib/config/constants.dart`:

```dart
class AppBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double extraLarge = 1440;
}
```

---

## Getting Screen Information

### 1. Using MediaQuery Extension (ScreenSize)

The `ScreenSize` extension on `MediaQueryData` provides convenient boolean getters:

```dart
final mediaQuery = MediaQuery.of(context);

// Check device type
if (mediaQuery.isMobile) {
  // Mobile-specific layout
}

if (mediaQuery.isTablet) {
  // Tablet-specific layout
}

if (mediaQuery.isDesktop) {
  // Desktop-specific layout
}

if (mediaQuery.isLargeScreen) {
  // Extra large screens
}

// Get device type
final deviceType = mediaQuery.deviceType;
// Returns: DeviceType.mobile, DeviceType.tablet, DeviceType.desktop, or DeviceType.extraLarge
```

### 2. Using ResponsiveValue Class

For complex responsive values with fallbacks:

```dart
final responsiveValue = ResponsiveValue(
  mobile: 16.0,
  tablet: 20.0,
  desktop: 24.0,
);

final fontSize = responsiveValue.getValue(mediaQuery.size.width);
```

---

## Adaptive Padding and Sizing

### AppResponsivePadding Class

Provides automatic responsive spacing and sizing based on screen width:

```dart
final mediaQuery = MediaQuery.of(context);
final responsivePadding = AppResponsivePadding(mediaQuery);

// Responsive horizontal padding
Padding(
  padding: responsivePadding.horizontalPadding,
  child: // content
)

// Responsive vertical padding
Padding(
  padding: responsivePadding.verticalPadding,
  child: // content
)

// Responsive all-sides padding
Padding(
  padding: responsivePadding.allPadding,
  child: // content
)
```

### Available Methods

| Method | Description | Mobile | Tablet | Desktop |
|--------|-------------|--------|--------|---------|
| `horizontalPadding` | Left & right padding | 16px | 20px | 24px |
| `verticalPadding` | Top & bottom padding | 16px | 20px | 24px |
| `allPadding` | All sides padding | 16px | 20px | 24px |
| `sectionGap` | Space between sections | 32px | 40px | 48px |
| `buttonHeight` | Button height | 48px | 52px | 56px |
| `iconSize` | Icon dimensions | 24px | 28px | 32px |
| `logoSize` | Logo dimensions | 120px | 140px | 160px |

---

## Implementation Examples

### SafeArea Usage

All screens should wrap their body content with `SafeArea` to avoid overlapping with system UI (notches, status bars, etc.):

```dart
@override
Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final responsivePadding = AppResponsivePadding(mediaQuery);
  final isMobile = mediaQuery.isMobile;

  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: responsivePadding.horizontalPadding,
          child: Column(
            children: [
              // Content here
            ],
          ),
        ),
      ),
    ),
  );
}
```

### Responsive Font Sizes

Use ternary operators to adjust font sizes based on device type:

```dart
Text(
  'Heading',
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    fontSize: isMobile ? 18 : 20,
  ),
)
```

### Responsive Image Sizes

Adjust image dimensions based on screen size:

```dart
Image.asset(
  'assets/images/logo.png',
  width: responsivePadding.logoSize,
  height: responsivePadding.logoSize,
  fit: BoxFit.cover,
)
```

### Responsive Button Heights

Use the responsive padding helper for consistent button heights:

```dart
ElevatedButton(
  onPressed: () {},
  child: SizedBox(
    height: responsivePadding.buttonHeight,
    child: Text('Click Me'),
  ),
)
```

### Responsive Spacing Between Sections

Use `sectionGap` for consistent spacing between major sections:

```dart
Column(
  children: [
    _buildSection1(),
    SizedBox(height: responsivePadding.sectionGap),
    _buildSection2(),
    SizedBox(height: responsivePadding.sectionGap),
    _buildSection3(),
  ],
)
```

### Conditional Layout Based on Device Type

```dart
if (isMobile) {
  // Stack widgets vertically for mobile
  Column(
    children: [widget1, widget2, widget3],
  );
} else {
  // Use grid or horizontal layout for tablet/desktop
  GridView.count(
    crossAxisCount: 2,
    children: [widget1, widget2, widget3],
  );
}
```

---

## Applied to Current Screens

### Login Screen (`lib/screens/auth/login_screen.dart`)

- ✅ Wrapped with `SafeArea`
- ✅ Uses `AppResponsivePadding` for horizontal padding
- ✅ Uses `responsivePadding.logoSize` for app logo
- ✅ Uses `responsivePadding.buttonHeight` for login button
- ✅ Adaptive spacing between sections using `responsivePadding.sectionGap`
- ✅ Dynamic font sizes based on `isMobile` flag

### Signup Screen (`lib/screens/auth/signup_screen.dart`)

- ✅ Wrapped with `SafeArea`
- ✅ Responsive logo size and padding
- ✅ Adaptive button height and spacing
- ✅ Container padding adjusts based on device type
- ✅ Font sizes scale with screen size

### Home Screen (`lib/screens/home/home_screen.dart`)

- ✅ Wrapped with `SafeArea`
- ✅ App bar title font size adapts to device
- ✅ Uses responsive padding throughout
- ✅ Section gaps scale with `responsivePadding.sectionGap`
- ✅ All spacing values are adaptive

---

## Best Practices

### 1. Always Use SafeArea for Body Content
```dart
body: SafeArea(
  child: // Your content
)
```

### 2. Use MediaQuery Extension for Simple Checks
```dart
if (mediaQuery.isMobile) {
  // Simpler than checking width manually
}
```

### 3. Use AppResponsivePadding for Consistency
```dart
// Good
padding: responsivePadding.horizontalPadding

// Avoid
padding: EdgeInsets.symmetric(horizontal: screenWidth < 480 ? 16 : 24)
```

### 4. Combine Conditional Logic with Responsive Values
```dart
SizedBox(
  height: isMobile ? AppSpacing.xl : AppSpacing.xxl,
)
```

### 5. Test on Multiple Device Sizes
- Test on actual mobile devices (320px-480px)
- Test on tablets (480px-1024px)
- Test on large screens (1024px+)
- Test in both portrait and landscape orientations

### 6. Use Expanded/Flexible for Layout Adaptation
```dart
Row(
  children: [
    Expanded(
      child: widget1,
    ),
    Expanded(
      child: widget2,
    ),
  ],
)
```

---

## Device Type Detection Summary

| Property | Type | Example |
|----------|------|---------|
| `mediaQuery.isMobile` | bool | true on phones < 480px |
| `mediaQuery.isTablet` | bool | true on 480px - 768px |
| `mediaQuery.isDesktop` | bool | true on 768px - 1024px |
| `mediaQuery.isLargeScreen` | bool | true on screens ≥ 1024px |
| `mediaQuery.deviceType` | DeviceType | mobile, tablet, desktop, extraLarge |
| `mediaQuery.size.width` | double | Exact screen width in pixels |
| `mediaQuery.size.height` | double | Exact screen height in pixels |
| `mediaQuery.padding.top` | double | Status bar height |
| `mediaQuery.padding.bottom` | double | Navigation bar height |

---

## File References

- **Constants**: [lib/config/constants.dart](lib/config/constants.dart) - AppBreakpoints, DeviceType, ScreenSize extension, AppResponsivePadding
- **Theme**: [lib/config/theme.dart](lib/config/theme.dart) - Material 3 theme with responsive text styles
- **Login Screen**: [lib/screens/auth/login_screen.dart](lib/screens/auth/login_screen.dart) - Responsive authentication screen
- **Signup Screen**: [lib/screens/auth/signup_screen.dart](lib/screens/auth/signup_screen.dart) - Responsive registration screen
- **Home Screen**: [lib/screens/home/home_screen.dart](lib/screens/home/home_screen.dart) - Responsive dashboard

---

## Future Enhancements

1. **Landscape Mode Support** - Optimize layouts for landscape orientation
2. **Tablet-Specific Layouts** - Create dedicated tablet UI patterns
3. **Desktop Navigation** - Add sidebar navigation for large screens
4. **Multi-Column Grids** - Implement responsive grid systems for cipher boards
5. **Animation Scaling** - Adjust animation durations based on device capability
6. **Performance Optimization** - Lazy load assets based on device resolution

---

## Troubleshooting

### Issue: Text Overflowing on Small Screens
**Solution**: Use `responsivePadding.horizontalPadding` and wrap text with `SingleChildScrollView` or set `softWrap: true`

### Issue: Buttons Too Small on Large Screens
**Solution**: Use `responsivePadding.buttonHeight` instead of fixed values

### Issue: Layout Doesn't Adapt on Device Rotation
**Solution**: Ensure `mediaQuery.size` is recalculated in `build()` - avoid storing sizes in variables

### Issue: Content Hidden Behind App Bar
**Solution**: Always wrap body content with `SafeArea`

---

## Testing Checklist

- [ ] Layout looks good on mobile (320px width)
- [ ] Layout looks good on tablet (600px width)
- [ ] Layout looks good on desktop (1000px+ width)
- [ ] No text overflow on any screen size
- [ ] All buttons are easily tappable (minimum 48dp height)
- [ ] All images scale appropriately
- [ ] SafeArea prevents overlap with system UI
- [ ] Spacing is consistent and proportional
- [ ] Test in both portrait and landscape

---

**Last Updated**: 2024
**Maintainer**: Cryptography Visualizer Team
