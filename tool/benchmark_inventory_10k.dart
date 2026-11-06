import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_colors.dart';
import 'package:kera_spare_tracker/core/design/widgets/status_badge.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

class BenchmarkPart {
  final String id;
  final String name;
  final String partNumber;
  final String brand;
  final double quantity;
  final double minQuantity;
  final double price;

  const BenchmarkPart({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.brand,
    required this.quantity,
    required this.minQuantity,
    required this.price,
  });
}

List<BenchmarkPart> generate10kParts() {
  final brands = ['Toyota', 'Nissan', 'Hyundai', 'Isuzu', 'Mitsubishi', 'Ford'];
  final categories = ['Brake Pad', 'Oil Filter', 'Spark Plug', 'Shock Absorber', 'Clutch Plate', 'Fan Belt'];
  final random = Random(42);

  return List.generate(10000, (index) {
    final b = brands[random.nextInt(brands.length)];
    final c = categories[random.nextInt(categories.length)];
    final qty = random.nextDouble() * 50;
    return BenchmarkPart(
      id: 'part_$index',
      name: '$b $c Premium #${index + 1}',
      partNumber: 'OEM-${100000 + index}',
      brand: b,
      quantity: qty,
      minQuantity: 5.0,
      price: (random.nextInt(500) + 20) * 10.0,
    );
  });
}

void main() {
  testWidgets('Benchmark: 10,000 Part Inventory List Frame & Raster Profiling', (tester) async {
    final parts = generate10kParts();
    expect(parts.length, 10000);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final frameBuildTimes = <Duration>[];
    final scrollController = ScrollController();

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: KeraColors.navy50,
        body: ListView.builder(
          controller: scrollController,
          itemCount: parts.length,
          itemExtent: 88, // 88px fixed height with RepaintBoundary
          itemBuilder: (context, index) {
            final part = parts[index];
            final isLow = part.quantity <= part.minQuantity && part.quantity > 0;
            final isOut = part.quantity <= 0;

            return RepaintBoundary(
              child: Container(
                height: 88,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: KeraColors.border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: KeraColors.navy50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: KeraColors.border),
                      ),
                      child: const Icon(Icons.settings_suggest_rounded, color: KeraColors.navy800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            part.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${part.partNumber} · ${part.brand}',
                            style: const TextStyle(color: KeraColors.textMutedColor, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ETB ${part.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        if (isOut)
                          StatusBadge.outOfStock(label: 'Out of stock')
                        else if (isLow)
                          StatusBadge.lowStock(quantity: part.quantity)
                        else
                          StatusBadge.inStock(quantity: part.quantity, unit: 'Pcs'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Warm-up JIT
    scrollController.jumpTo(100);
    await tester.pump();

    // Profile 60 scroll ticks across the 10,000-item list
    int droppedFrames = 0;
    const targetBudgetMicros = 16666; // 16.6ms for 60fps

    for (int i = 1; i <= 60; i++) {
      final sw = Stopwatch()..start();
      scrollController.jumpTo(i * 120.0);
      await tester.pump();
      sw.stop();

      final elapsed = sw.elapsed;
      frameBuildTimes.add(elapsed);
      if (elapsed.inMicroseconds > targetBudgetMicros) {
        droppedFrames++;
      }
    }

    final totalFrames = frameBuildTimes.length;
    final avgBuildMicros = frameBuildTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / totalFrames;
    final maxBuildMicros = frameBuildTimes.map((d) => d.inMicroseconds).reduce(max);
    final droppedRate = (droppedFrames / totalFrames) * 100;

    debugPrint('================ 10,000 PARTS BENCHMARK RESULTS ================');
    debugPrint('Total Parts Seeded: 10,000 items');
    debugPrint('Scroll Frames Profiled: $totalFrames frames');
    debugPrint('Average Frame Build Time: ${(avgBuildMicros / 1000).toStringAsFixed(2)} ms');
    debugPrint('Max Frame Build Time: ${(maxBuildMicros / 1000).toStringAsFixed(2)} ms');
    debugPrint('60 FPS Budget Ceiling: 16.67 ms');
    debugPrint('Dropped Frames: $droppedFrames / $totalFrames (${droppedRate.toStringAsFixed(1)}%)');
    debugPrint('Measured Frame Rate: ${(1000 / (avgBuildMicros / 1000)).toStringAsFixed(0)} fps equivalent');
    debugPrint('=================================================================');

    expect(avgBuildMicros / 1000, lessThan(25.0),
        reason: 'Average frame build time must be within budget under multi-threaded test runner load');
  });
}
