import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vendor_app/app/app.dart';

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: VendorApp()));
    await tester.pumpAndSettle();

    expect(find.text('Vendor sign in'), findsOneWidget);
  });
}
