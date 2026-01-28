# 🎨 Styling Quick Reference Card

## Colors at a Glance

```
PRIMARY     SECONDARY   SUCCESS     ERROR       WARNING     GREY        WHITE
#7C3AED     #2196F3     #4CAF50     #F44336     #FFC107     #9E9E9E     #FFFFFF
  ███         ███         ███         ███         ███         ███         ███
Deep Purple  Blue       Green        Red        Yellow      Medium      White
```

### Usage
- **Purple**: Headers, primary buttons, focused inputs
- **Blue**: Secondary actions, info sections
- **Green**: Success messages, confirmations
- **Red**: Errors, validation failures
- **Yellow**: Warnings, cautions
- **Grey**: Disabled states, secondary text

---

## Spacing Ruler

```
│ xs  │ sm  │ md  │ lg  │ xl  │ xxl │ xxxl │
│ 4dp │ 8dp │12dp │16dp │20dp │24dp │32dp  │
└─────┴─────┴─────┴─────┴─────┴─────┴──────┘
```

### Common Uses
- **xs (4dp)**: Icon spacing, tight gaps
- **sm (8dp)**: Between small elements
- **md (12dp)**: Component internal spacing
- **lg (16dp)**: Card padding, input padding ⭐ MOST USED
- **xl (20dp)**: Between related sections
- **xxl (24dp)**: Section separations
- **xxxl (32dp)**: Screen padding

---

## Border Radius Reference

```
sm          md          lg          xl          xxl         circle
4px         8px         12px        16px        20px        50px
┌─┐         ┌──┐        ┌───┐       ┌────┐     ┌─────┐     ┌──────┐
└─┘         └──┘        └───┘       └────┘     └─────┘     └──────┘
```

### Standard Usage
- **sm**: Small buttons, chips, minor elements
- **md**: Dialog corners, subtle containers
- **lg**: Cards, input fields, default choice ⭐
- **xl**: Welcome sections, large containers
- **xxl**: Dialog boxes, major sections
- **circle**: Avatar, icon buttons, floating actions

---

## Shadow Elevation Reference

```
┌─────────────┐                    (sm) Minimal shadow
├─────────────┤  ▬  2px elevation   
│             │  ▬  4px blur
└─────────────┘


┌─────────────┐                    (md) Card shadow - DEFAULT
├─────────────┤  ▬  4px elevation
│             │  ▬  8px blur       
└─────────────┘


┌─────────────┐                    (lg) Elevated card
├─────────────┤  ▬  8px elevation
│             │  ▬  12px blur
└─────────────┘


┌─────────────┐                    (xl) Prominent
├─────────────┤  ▬  16px elevation
│             │  ▬  24px blur
└─────────────┘
```

### When to Use
- **sm**: Subtle depth on text/borders
- **md**: Cards, stat cards ⭐ DEFAULT
- **lg**: Elevated sections, modals
- **xl**: Floating action buttons, overlays

---

## Typography Scale

```
Headline 1  ████████  32px  bold   (#000000)
Headline 2  ███████   28px  bold   (#000000)  
Headline 3  ██████    24px  bold   (#000000)
Title L     █████     20px  w600   (#000000)
Title M     ████      18px  w600   (#000000)
Title S     ███       16px  w600   (#424242)
Body L      ████      16px  w500   (#000000)
Body M      ███       14px  w400   (#9E9E9E)  ← Standard body
Body S      ██        12px  w400   (#9E9E9E)
Label L     ████      16px  w600   (#FFFFFF)  ← Button text
Label M     ███       14px  w600   (#FFFFFF)
```

### Common Usage
- **Headlines**: Page titles, major sections
- **Titles**: Card headers, section headers
- **Body**: Content text ⭐ MOST USED
- **Label**: Button text, form labels
- **Caption**: Helper text, secondary info

---

## Quick Component Templates

### Button (Primary)
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
  child: const Text('Label'),
)
```

### Card
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

### Input Field
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
    prefixIcon: const Icon(Icons.icon),
    contentPadding: const EdgeInsets.symmetric(
      vertical: AppSpacing.lg,
      horizontal: AppSpacing.lg,
    ),
  ),
)
```

### Stat Card (3-Column Grid)
```dart
Row(
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(...),
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    Expanded(...),
    const SizedBox(width: AppSpacing.md),
    Expanded(...),
  ],
)
```

---

## Color Combinations (Accessible)

### Text on Light Background
```
Black on White         ✅ WCAG AAA (21:1 contrast)
Purple on Light        ✅ WCAG AA (4.5:1 contrast)
Grey on White          ✅ WCAG AA (4.5:1 contrast)
```

### Text on Colored Background
```
White on Purple        ✅ WCAG AAA
White on Blue          ✅ WCAG AAA
White on Green         ✅ WCAG AAA
```

---

## Layout Grid Template

```
┌─────────────────────────────────────────┐
│ AppBar (Purple background)              │
├─────────────────────────────────────────┤
│ └─ EdgeInsets: lg horizontal, xxl top  │
│                                         │
│    ┌───────────────────────────────┐   │
│    │ Welcome Card (Gradient)       │   │  
│    │ lg padding, elevation: 4      │   │
│    │ gradient: primaryGradient     │   │
│    └───────────────────────────────┘   │
│                 ↓ xxxl spacing         │
│    ┌───────────────────────────────┐   │
│    │ ┌────┐  ┌────┐  ┌────┐       │   │
│    │ │Stat│  │Stat│  │Stat│       │   │
│    │ └────┘  └────┘  └────┘       │   │
│    │ spacing: md between columns  │   │
│    └───────────────────────────────┘   │
│                 ↓ xxxl spacing         │
│    ┌───────────────────────────────┐   │
│    │ Cipher Card                   │   │
│    │ lg padding, elevation: 2      │   │
│    │ lg spacing between sections   │   │
│    └───────────────────────────────┘   │
│                                         │
│ └─ EdgeInsets: lg horizontal, xxl bot  │
└─────────────────────────────────────────┘
```

---

## Do's & Don'ts Checklist

### ✅ DO
- [ ] Use `AppSpacing.*` for all spacing
- [ ] Use `AppColors.*` for all colors
- [ ] Use `AppRadius.*` for border radius
- [ ] Use `Theme.of(context).textTheme`
- [ ] Use `AppShadows.*` for elevation
- [ ] Use `AppGradients.*` for gradients
- [ ] Wrap screens with `SingleChildScrollView`
- [ ] Add padding to scrollable content
- [ ] Use `EdgeInsets.symmetric()` for consistency

### ❌ DON'T
- [ ] Don't hardcode spacing (no `16.0`)
- [ ] Don't use `Colors.grey[300]`
- [ ] Don't create custom `TextStyle`
- [ ] Don't mix Material 2 & Material 3
- [ ] Don't forget bottom padding on lists
- [ ] Don't use `withOpacity()` (use `withValues()`)
- [ ] Don't use inconsistent border radius
- [ ] Don't forget elevation on cards
- [ ] Don't center-align body text

---

## Color Hex Reference

```
AppColors.primary           #7C3AED  Deep Purple
AppColors.primaryLight      #EDE7F6  Light Purple
AppColors.primaryDark       #512DA8  Dark Purple

AppColors.secondary         #2196F3  Blue
AppColors.secondaryLight    #E3F2FD  Light Blue
AppColors.secondaryDark     #1565C0  Dark Blue

AppColors.success           #4CAF50  Green
AppColors.error             #F44336  Red
AppColors.warning           #FFC107  Yellow
AppColors.info              #2196F3  Light Blue

AppColors.white             #FFFFFF  White
AppColors.black             #000000  Black
AppColors.grey              #9E9E9E  Medium Grey
AppColors.greyDark          #424242  Dark Grey
AppColors.greyLight         #FAFAFA  Light Grey
AppColors.background        #FAFAFA  Background
AppColors.surface           #FFFFFF  Surface
AppColors.surfaceVariant    #F5F5F5  Surface Variant
```

---

## Import Template

```dart
import 'package:flutter/material.dart';
import '../../config/constants.dart';  // ← Always import

// Then use:
// - AppColors.primary
// - AppSpacing.lg
// - AppRadius.lg
// - AppShadows.cardShadow
// - AppGradients.primaryGradient
// - Theme.of(context).textTheme.bodyMedium
```

---

**Print this card** and keep it next to your development! 🎨
