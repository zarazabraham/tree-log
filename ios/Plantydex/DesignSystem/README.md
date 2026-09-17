# Plantydex Design System

A token-driven design system for the Plantydex iOS app built with SwiftUI.

## Architecture

The design system follows a layered architecture:

```
Tokens → Theme → Components → Screens
```

### 1. Tokens Layer

**Location:** `DesignSystem/Tokens/`

Tokens are the atomic values of the design system. They define the visual language and ensure consistency.

#### Available Token Files:

- **ColorTokens.swift** - Semantic colors that support light/dark mode
- **TypographyTokens.swift** - Text styles that support Dynamic Type
- **SpacingTokens.swift** - 8pt grid-based spacing scale
- **RadiiTokens.swift** - Border radius values
- **ElevationTokens.swift** - Shadow configurations for depth
- **MotionTokens.swift** - Animation durations and easing curves

### 2. Theme Layer

**Location:** `DesignSystem/Theme/`

The Theme object aggregates all tokens and provides them via SwiftUI Environment.

```swift
struct Theme {
    let colors: ColorTokens
    let typography: TypographyTokens
    let spacing: SpacingTokens
    let radii: RadiiTokens
    let elevation: ElevationTokens
    let motion: MotionTokens
}
```

### 3. Components Layer

**Location:** `DesignSystem/Components/`

Reusable UI components that consume tokens for all styling.

#### Available Components:

- **DSButton** - Primary, secondary, tertiary, and destructive buttons
- **DSCard** - Surface container for content
- **DSTextField** - Text input with label and error states
- **DSEmptyState** - Empty state with icon, message, and optional action
- **DSLoadingState** - Loading indicators (full-screen and inline)
- **DSErrorState** - Error states (full-screen and inline)
- **DSListRow** - Consistent list item with icon/image and accessories
- **DSImagePicker** - Camera and photo library picker

### 4. Screens Layer

**Location:** `ios/Plantydex/` (your existing screen files)

Screens compose components and access tokens via the Theme.

---

## Usage Guide

### Setting Up Theme

Wrap your app content with `ThemeProvider`:

```swift
@main
struct PlantydexApp: App {
    var body: some Scene {
        WindowGroup {
            ThemeProvider {
                TabView {
                    // Your screens
                }
            }
        }
    }
}
```

### Accessing Theme in Views

```swift
struct MyView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Text("Hello")
            .font(theme.typography.headingLarge)
            .foregroundColor(theme.colors.textPrimary)
            .padding(theme.spacing.md)
    }
}
```

### Using Components

#### Buttons

```swift
// Primary button
DSButton("Identify Plant", icon: "leaf.fill", style: .primary) {
    // Action
}

// Secondary button
DSButton("Cancel", style: .secondary) {
    // Action
}

// Loading button
DSButton("Loading", isLoading: true) {
    // Action
}

// Disabled button
DSButton("Disabled") {}
    .disabled(true)
```

#### Cards

```swift
DSCard(elevation: .level2) {
    VStack(alignment: .leading, spacing: 12) {
        Text("Card Title")
            .font(theme.typography.headingMedium)
        Text("Card content goes here")
            .font(theme.typography.bodyMedium)
    }
}
```

#### Empty States

```swift
DSEmptyState(
    icon: "leaf",
    title: "No Plants Yet",
    message: "Start your collection",
    actionTitle: "Add Plant"
) {
    // Action
}
```

#### Loading States

```swift
// Full-screen loading
DSLoadingState(message: "Loading plants...")

// Inline loading
DSInlineLoading(message: "Identifying...")
```

#### Error States

```swift
// Full-screen error
DSErrorState(
    title: "Connection Failed",
    message: "Check your internet connection",
    retryAction: {
        // Retry logic
    }
)

// Inline error
DSInlineError(
    message: "Upload failed",
    retryAction: { /* Retry */ }
)
```

#### List Rows

```swift
List {
    DSListRow(
        title: "Monstera Deliciosa",
        subtitle: "Swiss Cheese Plant",
        icon: "leaf.fill"
    ) {
        Image(systemName: "chevron.right")
    }
}
```

#### Image Picker

```swift
@State private var imageData: Data?

DSImagePicker(selectedImageData: $imageData)
```

---

## Adding New Tokens

### Adding a New Color

1. Open `ColorTokens.swift`
2. Add your semantic color:

```swift
struct ColorTokens {
    // ... existing colors

    /// New semantic color
    let myNewColor = Color("MyNewColor", bundle: .main)
}
```

3. Add the color to the asset catalog (`Assets.xcassets`):
   - Create new Color Set
   - Name it "MyNewColor"
   - Set light and dark mode variants

4. Add fallback value:

```swift
static let fallback = ColorTokens(
    // ... existing fallbacks
    myNewColor: .purple
)
```

### Adding a New Spacing Value

1. Open `SpacingTokens.swift`
2. Add your spacing value (use 4pt increments):

```swift
struct SpacingTokens {
    // ... existing spacing

    /// 28pt - My custom spacing
    let mySpacing: CGFloat = 28
}
```

3. Add to the enum:

```swift
enum SpacingValue {
    // ... existing cases
    case mySpacing

    var value: CGFloat {
        let tokens = SpacingTokens()
        switch self {
        // ... existing cases
        case .mySpacing: return tokens.mySpacing
        }
    }
}
```

### Adding a New Typography Style

1. Open `TypographyTokens.swift`
2. Add your text style:

```swift
struct TypographyTokens {
    // ... existing styles

    /// My custom text style
    let myCustomStyle = Font.system(.body, design: .default, weight: .semibold)
}
```

3. Add to the enum:

```swift
enum TextStyle {
    // ... existing cases
    case myCustomStyle
}

private struct TextStyleModifier: ViewModifier {
    func font(for style: TextStyle) -> Font {
        let typography = theme.typography
        switch style {
        // ... existing cases
        case .myCustomStyle: return typography.myCustomStyle
        }
    }
}
```

---

## Creating New Components

When creating a new component, follow these rules:

### 1. Component Structure

```swift
import SwiftUI

/// Description of what this component does
struct DSMyComponent: View {
    @Environment(\.theme) private var theme

    // Props
    let title: String
    let action: () -> Void

    var body: some View {
        // Use theme tokens for ALL styling
        Text(title)
            .font(theme.typography.bodyLarge)
            .foregroundColor(theme.colors.textPrimary)
            .padding(theme.spacing.md)
            .background(theme.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
            .elevation(.level2)
    }
}
```

### 2. No Magic Numbers

❌ **Bad:**
```swift
.padding(16)
.cornerRadius(12)
.shadow(radius: 4)
```

✅ **Good:**
```swift
.padding(theme.spacing.md)
.clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
.elevation(.level2)
```

### 3. Support All States

Components should handle:
- ✅ Default state
- ✅ Disabled state
- ✅ Loading state (if applicable)
- ✅ Error state (if applicable)
- ✅ Empty state (if applicable)

### 4. Provide Previews

Always include multiple previews:

```swift
#Preview("Default State") {
    ThemeProvider {
        DSMyComponent(title: "Hello") {}
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        DSMyComponent(title: "Hello") {}
    }
    .preferredColorScheme(.dark)
}
```

---

## Refactoring Existing Screens

When refactoring a screen to use the design system:

### Step 1: Wrap with ThemeProvider (if not already)

```swift
@main
struct PlantydexApp: App {
    var body: some Scene {
        WindowGroup {
            ThemeProvider {
                // Your content
            }
        }
    }
}
```

### Step 2: Access Theme

```swift
struct MyScreen: View {
    @Environment(\.theme) private var theme

    var body: some View {
        // ... your view code
    }
}
```

### Step 3: Replace Hard-coded Values

Find and replace:

| Old | New |
|-----|-----|
| `.padding(16)` | `.padding(theme.spacing.md)` |
| `.cornerRadius(10)` | `.clipShape(RoundedRectangle(cornerRadius: theme.radii.button))` |
| `.foregroundColor(.green)` | `.foregroundColor(theme.colors.primary)` |
| `.font(.headline)` | `.font(theme.typography.headingMedium)` |
| `.shadow(radius: 2)` | `.elevation(.level2)` |

### Step 4: Replace Custom UI with Components

| Old | New |
|-----|-----|
| Custom button code | `DSButton(...)` |
| Custom card wrapper | `DSCard { ... }` |
| Custom empty view | `DSEmptyState(...)` |
| `ProgressView` with text | `DSLoadingState(...)` |
| Custom error view | `DSErrorState(...)` |

### Step 5: Add State Views

Ensure screens handle all states:

```swift
struct MyScreen: View {
    @State private var isLoading = false
    @State private var error: String?
    @State private var items: [Item] = []

    var body: some View {
        Group {
            if isLoading {
                DSLoadingState(message: "Loading...")
            } else if let error = error {
                DSErrorState(message: error) {
                    loadData()
                }
            } else if items.isEmpty {
                DSEmptyState(
                    icon: "tray",
                    title: "No Items",
                    message: "Get started by adding an item"
                )
            } else {
                List(items) { item in
                    DSListRow(title: item.name)
                }
            }
        }
    }
}
```

---

## Best Practices

### DO:
✅ Use semantic token names (e.g., `primary`, `textSecondary`)
✅ Access tokens via `theme` environment value
✅ Use components for all UI elements
✅ Support Dynamic Type and accessibility
✅ Test in both light and dark mode
✅ Provide previews for all states

### DON'T:
❌ Hard-code colors, fonts, spacing, or radii
❌ Use hex colors or RGB values
❌ Use magic numbers for padding or sizing
❌ Create custom UI when a component exists
❌ Skip accessibility considerations
❌ Forget to handle loading/error/empty states

---

## File Structure

```
ios/Plantydex/
├── DesignSystem/
│   ├── Tokens/
│   │   ├── ColorTokens.swift
│   │   ├── TypographyTokens.swift
│   │   ├── SpacingTokens.swift
│   │   ├── RadiiTokens.swift
│   │   ├── ElevationTokens.swift
│   │   └── MotionTokens.swift
│   ├── Theme/
│   │   └── Theme.swift
│   ├── Components/
│   │   ├── DSButton.swift
│   │   ├── DSCard.swift
│   │   ├── DSTextField.swift
│   │   ├── DSEmptyState.swift
│   │   ├── DSLoadingState.swift
│   │   ├── DSErrorState.swift
│   │   ├── DSListRow.swift
│   │   └── DSImagePicker.swift
│   └── README.md (this file)
└── [Existing screen files]
```

---

## Examples

See the preview sections in each component file for comprehensive examples of usage patterns.

---

## Support

For questions or issues with the design system, refer to this guide or check the preview implementations in each component file.
