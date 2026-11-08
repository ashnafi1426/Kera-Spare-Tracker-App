import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/widgets/bottom_nav.dart';
import 'package:kera_spare_tracker/core/router/app_router.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/sales_pos_screen.dart';

class _FakeAuthController extends AuthController {
  final AuthUser? user;
  _FakeAuthController(this.user);

  @override
  Future<AuthUser?> build() async => user;
}

void main() {
  const ownerUser = AuthUser(
    id: 'user_1',
    businessName: 'House keeper',
    role: 'owner',
    status: 'active',
    ownerId: 'owner_1',
    phoneNumber: '+251911000000',
  );

  testWidgets('When navigating to /sales, BottomNav footer is rendered', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(ownerUser)),
      ],
    );

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Now go to /sales
    router.go('/sales');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify SalesPosScreen is displayed
    expect(find.byType(SalesPosScreen), findsOneWidget);

    // Verify BottomNav is displayed
    expect(find.byType(BottomNav), findsOneWidget);

    // Verify BottomNav has Sell highlighted
    final bottomNav = tester.widget<BottomNav>(find.byType(BottomNav));
    expect(bottomNav.currentIndex, 4);
  });
}
