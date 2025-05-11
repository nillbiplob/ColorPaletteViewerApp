import SwiftUI

struct PaletteCategory: Codable {
    let name: String
    let palettes: [ColorPalette]
}

struct ColorPalette: Codable {
    let name: String
    let colors: [String]
}

struct ColorPaletteScreen: View {
    @State private var categories: [PaletteCategory] = []
    @State private var selectedCategory = 0
    @State private var selectedPaletteIndex = 0
    @State private var selectedColorIndex = 0
    @State private var textCount = 3

    var body: some View {
        VStack(spacing: 0) {
            if categories.isEmpty {
                ProgressView().onAppear { loadPalettes() }
            } else {
                let palette = categories[selectedCategory].palettes[selectedPaletteIndex].colors
                let backgroundColor = Color(hex: palette[selectedColorIndex])
                let foregroundColors = generateForegroundColors(palette: palette, backgroundHex: palette[selectedColorIndex], count: textCount)

                ZStack {
                    backgroundColor.ignoresSafeArea()

                    VStack {
                        Spacer()
                        ForEach(0..<textCount, id: \.self) { i in
                            Text("I love my country")
                                .font(.largeTitle.bold())
                                .foregroundColor(Color(uiColor: foregroundColors[i % foregroundColors.count]))
                        }
                        Spacer()
                    }
                }

                TabView(selection: $selectedCategory) {
                    ForEach(0..<categories.count, id: \.self) { idx in
                        Text(categories[idx].name)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 40)

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(0..<categories[selectedCategory].palettes.count, id: \.self) { idx in
                            let palette = categories[selectedCategory].palettes[idx].colors
                            VStack(spacing: 0) {
                                ForEach(palette, id: \.self) { hex in
                                    Color(hex: hex)
                                        .frame(height: 80 / CGFloat(palette.count))
                                }
                            }
                            .frame(width: 40)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .stroke(idx == selectedPaletteIndex ? Color.white : Color.clear, lineWidth: 2))
                            .onTapGesture {
                                if selectedPaletteIndex == idx {
                                    selectedColorIndex = (selectedColorIndex + 1) % palette.count
                                } else {
                                    selectedPaletteIndex = idx
                                    selectedColorIndex = 0
                                    textCount = Int.random(in: 3...5)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black)
                }
            }
        }
    }

    private func loadPalettes() {
        guard let url = Bundle.main.url(forResource: "palettes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode([String: [PaletteCategory]].self, from: data),
              let categories = json["categories"] else {
            return
        }
        self.categories = categories
    }

    private func generateForegroundColors(palette: [String], backgroundHex: String, count: Int) -> [UIColor] {
        let bgColor = UIColor(hex: backgroundHex)
        let fromPalette = palette
            .filter { $0.lowercased() != backgroundHex.lowercased() }
            .map { UIColor(hex: $0) }
            .filter { bgColor.contrastRatio(with: $0) >= 3.0 }
            .prefix(count / 2)

        let fallbackColors: [UIColor] = [
            .white, .black, UIColor(hex: "#F5F5F5"), UIColor(hex: "#FAFAFA"),
            UIColor(hex: "#E0E0E0"), UIColor(hex: "#1A1A1A"), UIColor(hex: "#333333")
        ]

        let fromFallback = fallbackColors.filter { bgColor.contrastRatio(with: $0) >= 3.0 }
            .prefix(count - fromPalette.count)

        var results = Array(fromPalette) + Array(fromFallback)

        while results.count < count {
            let hsl = bgColor.hsl
            let shifted = hsl.withLightness(hsl.l < 0.5 ? hsl.l + 0.4 : hsl.l - 0.4)
            let newColor = shifted.toUIColor()
            if bgColor.contrastRatio(with: newColor) >= 3.0 {
                results.append(newColor)
            }
        }
        return results
    }
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    func contrastRatio(with other: UIColor) -> CGFloat {
        let l1 = self.luminance, l2 = other.luminance
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    var luminance: CGFloat {
        func adjust(_ v: CGFloat) -> CGFloat {
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055)/1.055, 2.4)
        }

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        return 0.2126 * adjust(r) + 0.7152 * adjust(g) + 0.0722 * adjust(b)
    }

    var hsl: (h: CGFloat, s: CGFloat, l: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let l = (2 - s) * b / 2
        return (h, s, l)
    }

    func withLightness(_ newL: CGFloat) -> (h: CGFloat, s: CGFloat, l: CGFloat) {
        let hsl = self.hsl
        return (hsl.h, hsl.s, newL)
    }

    func toUIColor() -> UIColor {
        let hsl = self.hsl
        return UIColor(hue: hsl.h, saturation: hsl.s, brightness: hsl.l * 2, alpha: 1)
    }
}
