🎨 Color Palette Viewer App
A minimal yet powerful Flutter and SwiftUI demo that dynamically visualizes color palettes grouped by category. This project helps in testing background + foreground color combinations for UI/UX design, accessibility, and brand styling.

📸 Preview
Flutter (Android/iOS)	SwiftUI (iOS/macOS)



🚀 Features
✅ Load palettes from structured JSON
✅ Group palettes into named categories with horizontal tabs
✅ Tap palettes to cycle background color
✅ Automatically generate optimal foreground colors (text/icons)
✅ Fallback & HSL-based contrast extender for accessibility
✅ Adaptive layout for both light and dark themes
✅ Cross-platform (Flutter & SwiftUI)

📁 JSON Format Example
assets/palettes.json:

json
Copy
Edit
{
"categories": [
{
"name": "Warm",
"palettes": [
{
"name": "W1",
"colors": ["#D3045D", "#E484AC", "#740C08", "#B3CED6", "#927B67", "#523F2B"]
}
]
}
]
}
Each palette contains 4–6 hex color codes

The first selected color is used as background

Other colors are filtered for foreground use (contrast-aware)

📦 Getting Started
🐦 Flutter
Clone this repo

Ensure Flutter is installed (flutter doctor)

Run the app:

bash
Copy
Edit
flutter pub get
flutter run
Edit or replace assets/palettes.json to update color sets.

⚠️ Don’t forget to declare the asset in pubspec.yaml:

yaml
Copy
Edit
flutter:
assets:
- assets/palettes.json
🍏 SwiftUI
Open ColorPaletteDemo.xcodeproj in Xcode

Ensure palettes.json is added to the main app bundle

Run on iOS Simulator or macOS Catalyst

🧠 How It Works
Foreground colors are selected from:

Palette itself (with contrast ratio ≥ 3.0)

Fallback list (white, black, grays)

Dynamically lightened/darkened colors (HSL-based)

WCAG contrast compliance is maintained for text readability.

🤝 Contributions
If you’d like to:

Add more JSON examples

Extend with gradient or typography testing

Improve HSL tuning
Feel free to fork, PR, or file an issue!

📄 License
MIT License — feel free to use, modify, and share.

