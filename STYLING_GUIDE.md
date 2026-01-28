# Cryptography Visualizer - Styling & Layout Guide

## 📋 Overview
This document outlines all the styling principles and layout guidelines applied throughout the Cryptography Visualizer application.

---

## 🎨 Design System

### Color Palette (`AppColors`)
- **Primary Color**: `#7C3AED` (Deep Purple)
- **Primary Light**: `#EDE7F6`
- **Secondary Color**: `#2196F3` (Blue)
- **Secondary Light**: `#E3F2FD`
- **Success**: `#4CAF50` (Green)
- **Error**: `#F44336` (Red)
- **Warning**: `#FFC107` (Yellow)
- **Background**: `#FAFAFA` (Light Grey)
- **Surface**: `#FFFFFF` (White)

### Spacing System (`AppSpacing`)
All spacing values follow a consistent 4dp baseline:
- `xs`: 4dp
- `sm`: 8dp
- `md`: 12dp
- `lg`: 16dp
- `xl`: 20dp
- `xxl`: 24dp
- `xxxl`: 32dp

**Usage**: Replace hardcoded values like `16.0` with `AppSpacing.lg`

### Border Radius (`AppRadius`)
- `sm`: 4dp (small buttons, chips)
- `md`: 8dp (small containers)
- `lg`: 12dp (cards, input fields)
- `xl`: 16dp (welcome cards, large containers)
- `xxl`: 20dp (dialog boxes)
- `circle`: 50dp (circular elements)

### Typography (`AppText`)
Predefined text styles for consistency:
- **Headlines**: `headline1` to `headline3`
- **Subtitles**: `subtitle1`, `subtitle2`
- **Body**: `body1`, `body2`
- **Labels**: `label`, `labelSmall`
- **Caption**: `caption`

**Usage**: Use Theme.of(context).textTheme.headlineMedium instead of custom TextStyle()

### Shadows (`AppShadows`)
Pre-configured box shadows for elevation:
- `sm`: Minimal shadow (subtle)
- `md`: Medium shadow (cards)
- `lg`: Large shadow (elevated items)
- `xl`: Extra-large shadow (prominent items)
- `cardShadow`: Optimized for cards
- `elevatedShadow`: Optimized for elevated containers

**Usage**: 
```dart
boxShadow: AppShadows.cardShadow,
```

### Gradients (`AppGradients`)
Pre-defined gradient combinations:
- `primaryGradient`: Purple to Blue (main accent)
- `purpleToBlue`: Deep Purple to Blue
- `blueToTeal`: Blue to Teal
- `purpleToBlack`: Purple to Black

**Usage**:
```dart
decoration: BoxDecoration(
  gradient: AppGradients.primaryGradient,
)
```

---

## 🏗️ Layout Principles

### 1. **Meaningful & Consistent Color Usage**
- ✅ Primary color for main CTAs and headers
- ✅ Secondary color for alt actions and info sections
- ✅ Gray for disabled/secondary text
- ✅ Error color for validation errors only
- ✅ Success color for positive confirmations

### 2. **Adequate Spacing**
- Cards have `lg` (16dp) padding
- Sections separated by `xxl` (24dp) or `xxxl` (32dp)
- Text elements within cards use `md` (12dp) or `lg` (16dp)
- Input fields use `lg` (16dp) padding for touch targets

### 3. **Font Consistency**
- Use Material 3 text theme from `AppTheme`
- Headlines: 22-26px, bold weight
- Body text: 14-16px, regular weight
- Labels/Buttons: 14-16px, w600 (semi-bold)
- All colors match AppColors palette

### 4. **Card Elevation & Shadows**
- Cards use `elevation: 2` and `AppShadows.cardShadow`
- Elevated items (welcome section) use `AppShadows.elevatedShadow`
- Hover states increase shadow (not implemented yet)
- Border radius: 12-16dp for cards

### 5. **Proper Alignment**
- Vertical layouts use `crossAxisAlignment.start` for left-aligned text
- Center-aligned sections use `mainAxisAlignment.center`
- Padding applied consistently using EdgeInsets.symmetric()
- Cards use Column/Row with proper spacing

---

## 📱 Screen-Specific Styling

### Login Screen
- Background: `AppColors.background`
- Logo shadow: `AppShadows.elevatedShadow`
- Input fields use theme's `InputDecorationTheme`
- Button height: 56dp
- Button radius: `AppRadius.lg` (12dp)

### Signup Screen
- Same as Login with additional checkbox styling
- Checkbox container background: `AppColors.primaryLight`
- Terms section has subtle border: `AppColors.primary.withValues(alpha: 0.2)`

### Home Screen
- Welcome section: `AppGradients.primaryGradient`
- Stat cards: 3-column grid with `AppSpacing.md` gaps
- Cipher cards: Full-width with icon box
- Features section: Secondary color background (`AppColors.secondaryLight`)

---

## 🎯 Component Styling Standards

### Buttons
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.lg,
      horizontal: AppSpacing.xl,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
)
```

### Input Fields
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Hint',
    prefixIcon: Icon(Icons.icon),
    contentPadding: const EdgeInsets.symmetric(
      vertical: AppSpacing.lg,
      horizontal: AppSpacing.lg,
    ),
  ),
)
```

### Cards
```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.cardShadow,
  ),
  child: Column(...),
)
```

### Stat Cards
- Always in a Row with Expanded children
- Gap between cards: `AppSpacing.md` (12dp)
- Icon size: 24dp, color: `AppColors.primary`

---

## 🔄 Spacing Layout Pattern

### Standard Section Spacing
```
┌─────────────────────┐
│  Header (xxxl)      │
│                     │
│  Content Section    │
│                     │  ← xxxl (32dp) gap
│  Next Section       │
└─────────────────────┘
```

### Card Interior Spacing
```
┌──────────────────────────┐
│ lg padding (16dp)        │
│ ┌──────────────────────┐ │
│ │ Icon - lg gap - Text │ │
│ │         md (12dp)    │ │
│ │ Description          │ │
│ └──────────────────────┘ │
│ lg (16dp) gap            │
│ [Button - full width]    │
│ lg padding (16dp)        │
└──────────────────────────┘
```

---

## ✅ Validation & Best Practices

### Do's ✅
- Use `AppSpacing.*` constants instead of hardcoded values
- Use `AppColors.*` for all colors
- Use `AppRadius.*` for border radius values
- Use theme text styles from `Theme.of(context).textTheme`
- Use `AppGradients.*` for gradients
- Use `AppShadows.*` for box shadows
- Maintain 16-24dp padding for all screens
- Use Material 3 components and structure

### Don'ts ❌
- Don't use hardcoded colors like `Colors.grey[300]`
- Don't use inconsistent spacing (mix of 10, 15, 18dp)
- Don't create custom TextStyles; use theme
- Don't use `withOpacity()` for colors; use `withValues(alpha:)`
- Don't mix old Material 2 and Material 3 components
- Don't forget to add bottom padding for scrollable screens

---

## 📐 Responsive Design Notes

Current implementation uses:
- Fixed widths for stat cards using `Expanded`
- Full-width buttons with `SizedBox(width: double.infinity)`
- Flexible layouts with proper constraints
- No hardcoded device dimensions

Future enhancements:
- Add breakpoints for tablet layouts
- Implement adaptive column layouts (1 col mobile, 2-3 col tablet)
- Responsive font sizing based on screen size

---

## 🎭 Customizing for Cipher Screens

When creating Caesar Cipher or Playfair Cipher screens, follow these guidelines:

```dart
class CaesarCipherScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Caesar Cipher'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Section
              _buildInputCard(),
              const SizedBox(height: AppSpacing.xxl),
              
              // Visualization Section
              _buildVisualizationCard(),
              const SizedBox(height: AppSpacing.xxl),
              
              // Results Section
              _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📚 Reference Files
- Color & Spacing Constants: `lib/config/constants.dart`
- Theme Definition: `lib/config/theme.dart`
- Login Screen: `lib/screens/auth/login_screen.dart`
- Home Screen: `lib/screens/home/home_screen.dart`

---

## 🚀 Implementation Checklist

Before deploying new screens, ensure:
- [ ] All colors from `AppColors`
- [ ] All spacing from `AppSpacing`
- [ ] All border radius from `AppRadius`
- [ ] All shadows from `AppShadows`
- [ ] Text styles from theme
- [ ] Proper card elevation (2-4)
- [ ] 16-24dp section padding
- [ ] Icons properly sized (24dp default)
- [ ] Buttons 56dp height minimum
- [ ] Input fields with `lg` content padding
- [ ] No hardcoded color values
- [ ] No custom TextStyle definitions
- [ ] Consistent rounded corners
- [ ] Proper gradient usage

---

**Last Updated**: January 28, 2026
**Version**: 1.0.0
**Status**: ✅ Production Ready
