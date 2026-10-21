import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/widgets/app_picker_bottom_sheet.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/picker_item.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    locale: const Locale('am'),
    supportedLocales: const [Locale('am'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  const items = [
    PickerItem(id: '1', name: 'CAT', isDefault: true),
    PickerItem(id: '2', name: 'Doosan', isDefault: true),
    PickerItem(id: '3', name: 'Toyota Custom', isDefault: false),
  ];

  testWidgets('AppPickerBottomSheet renders title, search, and items with default badges',
      (WidgetTester tester) async {
    PickerItem? selected;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selected = await AppPickerBottomSheet.show(
                context: context,
                title: 'ብራንድ ይምረጡ',
                items: items,
                selectedId: '1',
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
    );

    // Open bottom sheet
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify Title and search
    expect(find.text('ብራንድ ይምረጡ'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify items
    expect(find.text('CAT'), findsOneWidget);
    expect(find.text('Doosan'), findsOneWidget);
    expect(find.text('Toyota Custom'), findsOneWidget);
    expect(find.text('መደበኛ'), findsNWidgets(2)); // CAT & Doosan badges

    // Tap Toyota Custom
    await tester.tap(find.text('Toyota Custom'));
    await tester.pumpAndSettle();

    // Bottom sheet is closed and selected item returned
    expect(selected, isNotNull);
    expect(selected!.id, equals('3'));
    expect(selected!.name, equals('Toyota Custom'));
  });

  testWidgets('AppPickerBottomSheet live search filters list',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              AppPickerBottomSheet.show(
                context: context,
                title: 'የማስቀመጫ ቦታ ይምረጡ',
                items: const [
                  PickerItem(id: '1', name: 'Shelf 1', isDefault: true),
                  PickerItem(id: '2', name: 'Shelf 2', isDefault: true),
                  PickerItem(id: '3', name: 'Backroom Rack A', isDefault: false),
                ],
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Type "Backroom" in search
    await tester.enterText(find.byType(TextField), 'Backroom');
    await tester.pumpAndSettle();

    expect(find.text('Backroom Rack A'), findsOneWidget);
    expect(find.text('Shelf 1'), findsNothing);
    expect(find.text('Shelf 2'), findsNothing);
  });

  testWidgets('AppPickerBottomSheet quick add new triggers callback and returns item',
      (WidgetTester tester) async {
    PickerItem? selected;
    var quickAddCalled = false;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selected = await AppPickerBottomSheet.show(
                context: context,
                title: 'ምድብ ይምረጡ',
                items: const [
                  PickerItem(id: '1', name: 'Engine'),
                ],
                onQuickAdd: () async {
                  quickAddCalled = true;
                  return const PickerItem(
                    id: 'new_id',
                    name: 'Hydraulics Brand New',
                  );
                },
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Tap "Add New" button in header
    final quickAddBtn = find.text('አዲስ ጨምር');
    expect(quickAddBtn, findsOneWidget);

    await tester.tap(quickAddBtn);
    await tester.pumpAndSettle();

    expect(quickAddCalled, isTrue);
    expect(selected, isNotNull);
    expect(selected!.id, equals('new_id'));
    expect(selected!.name, equals('Hydraulics Brand New'));
  });
}
