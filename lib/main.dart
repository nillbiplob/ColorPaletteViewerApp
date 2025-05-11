import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    MaterialApp(home: ColorPaletteScreen(), debugShowCheckedModeBanner: false),
  );
}

class ColorPaletteScreen extends StatefulWidget {
  @override
  _ColorPaletteScreenState createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<ColorPaletteScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> categories = [];
  late TabController _tabController;

  int selectedCategoryIndex = 0;
  int selectedPaletteIndex = 0;
  int selectedColorIndex = 0;
  int textCount = 3;

  @override
  void initState() {
    super.initState();
    _loadPalettesFromJson();
  }

  Future<void> _loadPalettesFromJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/palettes.json',
    );
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);

    categories =
        (jsonData['categories'] as List).map<Map<String, dynamic>>((cat) {
          return {
            'name': cat['name'],
            'palettes':
                (cat['palettes'] as List).map<List<Color>>((p) {
                  return (p['colors'] as List)
                      .map<Color>(
                        (c) => Color(int.parse(c.replaceFirst('#', '0xFF'))),
                      )
                      .toList();
                }).toList(),
          };
        }).toList();

    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedCategoryIndex = _tabController.index;
        selectedPaletteIndex = 0;
        selectedColorIndex = 0;
      });
    });

    setState(() {});
  }

  List<List<Color>> get palettes =>
      categories[selectedCategoryIndex]['palettes'];
  List<Color> get currentPalette => palettes[selectedPaletteIndex];
  Color get backgroundColor => currentPalette[selectedColorIndex];
  List<Color> get foregroundColors =>
      _generateForegroundColors(currentPalette, backgroundColor, textCount);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(textCount, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "I love my country",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: foregroundColors[i % foregroundColors.length],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Material(
              color: Colors.black,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.white,
                tabs: categories.map((cat) => Tab(text: cat['name'])).toList(),
              ),
            ),
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 8),
              color: Colors.black,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: palettes.length,
                itemBuilder: (context, index) {
                  final palette = palettes[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedPaletteIndex == index) {
                          selectedColorIndex =
                              (selectedColorIndex + 1) % palette.length;
                        } else {
                          selectedPaletteIndex = index;
                          selectedColorIndex = 0;
                          textCount = Random().nextInt(3) + 3;
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border:
                            selectedPaletteIndex == index
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children:
                            palette.map((color) {
                              final height = 80.0 / palette.length;
                              return Container(
                                height: height,
                                width: double.infinity,
                                color: color,
                              );
                            }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _generateForegroundColors(
    List<Color> palette,
    Color bg,
    int count,
  ) {
    final fromPalette =
        palette
            .where((c) => c != bg && _contrastRatio(bg, c) >= 3.0)
            .take(count ~/ 2)
            .toList();

    final fallbackPool = [
      Colors.white,
      Colors.black,
      Color(0xFFF5F5F5),
      Color(0xFFFAFAFA),
      Color(0xFFE0E0E0),
      Color(0xFF1A1A1A),
      Color(0xFF333333),
    ];

    final fromFallback =
        fallbackPool
            .where((c) => _contrastRatio(bg, c) >= 3.0)
            .take(count - fromPalette.length)
            .toList();

    final totalSoFar = fromPalette.length + fromFallback.length;

    // Use HSL-based extender if still short
    final fromHSL = <Color>[];
    if (totalSoFar < count) {
      final needed = count - totalSoFar;
      final hsl = HSLColor.fromColor(bg);

      for (int i = 0; i < needed; i++) {
        final double lightness =
            (i.isEven)
                ? (hsl.lightness < 0.5
                    ? hsl.lightness + 0.4
                    : hsl.lightness - 0.4)
                : (hsl.lightness < 0.5
                    ? hsl.lightness + 0.2
                    : hsl.lightness - 0.2);

        final adjusted = hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();

        // Only add if contrast is enough and it's unique
        if (_contrastRatio(bg, adjusted) >= 3.0 &&
            !fromPalette.contains(adjusted) &&
            !fromFallback.contains(adjusted)) {
          fromHSL.add(adjusted);
        }

        if (fromHSL.length >= needed) break;
      }
    }

    return [...fromPalette, ...fromFallback, ...fromHSL];
  }

  double _luminance(Color c) {
    final r = _channelLuminance(c.red / 255.0);
    final g = _channelLuminance(c.green / 255.0);
    final b = _channelLuminance(c.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _channelLuminance(double c) {
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  double _contrastRatio(Color c1, Color c2) {
    final l1 = _luminance(c1);
    final l2 = _luminance(c2);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}
