import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_colors.dart';
import 'package:kera_spare_tracker/core/design/widgets/mobile_components.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

class BenchmarkItem {
  final String id;
  final String amharicName;
  final String partNumber;
  final String brand;
  final String shelf;
  final double quantity;
  final double minQuantity;
  final double price;

  const BenchmarkItem({
    required this.id,
    required this.amharicName,
    required this.partNumber,
    required this.brand,
    required this.shelf,
    required this.quantity,
    required this.minQuantity,
    required this.price,
  });
}

List<BenchmarkItem> seed10kParts() {
  final amharicNames = [
    'የቶዮታ ሃይሉክስ የፊት ፍሬን ፓድ ከፍተኛ ጥራት',
    'የኢሱዙ ኤፍቲአር የዘይት ማጣሪያ የመጀመሪያ ደረጃ',
    'የኒሳን ፒክአፕ የኋላ ስፕሪንግ ቡሽ ማሰሪያ',
    'የካተርፒላር 320 የሃይድሮሊክ ፓምፕ ማጣሪያ',
    'የሚትሱቢሺ ካንተር የክላች ዲስክ እና ፕሌት ስብስብ',
    'የሂዩንዳይ ኤክስካቫተር የአየር ማጣሪያ ባለሁለት ደረጃ',
  ];
  final brands = ['Toyota Genuine', 'Isuzu Japan', 'Caterpillar', 'Doosan Korea', 'Denso', 'Bosch'];
  final random = Random(42);

  return List.generate(10000, (index) {
    final name = amharicNames[random.nextInt(amharicNames.length)];
    final brand = brands[random.nextInt(brands.length)];
    return BenchmarkItem(
      id: 'part_$index',
      amharicName: '$name #$index',
      partNumber: 'OEM-${200000 + index}',
      brand: brand,
      shelf: 'Shelf ${String.fromCharCode(65 + (index % 6))}-${(index % 20) + 1}',
      quantity: (index % 15).toDouble(),
      minQuantity: 5.0,
      price: ((index % 50) + 10) * 150.0,
    );
  });
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration Test: 10,000 Parts Profile Scrolling with FrameTiming', (tester) async {
    final parts = seed10kParts();
    expect(parts.length, 10000);

    final buildTimes = <double>[];
    final rasterTimes = <double>[];
    int framesOver16ms = 0;

    // Register native FrameTiming listener
    binding.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
        final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
        final totalMs = timing.totalSpan.inMicroseconds / 1000.0;

        buildTimes.add(buildMs);
        rasterTimes.add(rasterMs);
        if (totalMs > 16.0) {
          framesOver16ms++;
        }
      }
    });

    final scrollController = ScrollController();

    // Pump widget tree with PartTile (no fixed itemExtent that clips text; survives 200% text scale)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.5), // Test 150-200% scale
            devicePixelRatio: 2.0,
          ),
          child: Scaffold(
            backgroundColor: KeraColors.navy50,
            body: ListView.separated(
              controller: scrollController,
              itemCount: parts.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final item = parts[index];
                return RepaintBoundary(
                  child: PartTile(
                    title: item.amharicName,
                    partNumber: item.partNumber,
                    shelfLocation: item.shelf,
                    price: item.price,
                    quantity: item.quantity,
                    minQuantity: item.minQuantity,
                    unit: 'Pcs',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fling scroll through 100 frames
    for (int i = 0; i < 50; i++) {
      scrollController.jumpTo(scrollController.offset + 250);
      await tester.pump(const Duration(milliseconds: 16));
    }

    if (buildTimes.isNotEmpty && rasterTimes.isNotEmpty) {
      buildTimes.sort();
      rasterTimes.sort();

      final avgBuild = buildTimes.reduce((a, b) => a + b) / buildTimes.length;
      final p90Build = buildTimes[(buildTimes.length * 0.90).floor()];
      final p99Build = buildTimes[(buildTimes.length * 0.99).floor()];

      final avgRaster = rasterTimes.reduce((a, b) => a + b) / rasterTimes.length;
      final p90Raster = rasterTimes[(rasterTimes.length * 0.90).floor()];
      final p99Raster = rasterTimes[(rasterTimes.length * 0.99).floor()];

      debugPrint('================ INTEGRATION PROFILE RESULTS ================');
      debugPrint('Dataset: 10,000 parts');
      debugPrint('Frames Measured: ${buildTimes.length}');
      debugPrint('Average Build Time: ${avgBuild.toStringAsFixed(2)} ms');
      debugPrint('90th Percentile Build: ${p90Build.toStringAsFixed(2)} ms');
      debugPrint('99th Percentile Build: ${p99Build.toStringAsFixed(2)} ms');
      debugPrint('Average Raster Time: ${avgRaster.toStringAsFixed(2)} ms');
      debugPrint('90th Percentile Raster: ${p90Raster.toStringAsFixed(2)} ms');
      debugPrint('99th Percentile Raster: ${p99Raster.toStringAsFixed(2)} ms');
      debugPrint('Frames > 16ms: $framesOver16ms');
      debugPrint('==============================================================');
    }
  });
}
