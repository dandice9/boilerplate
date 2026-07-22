import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/app.dart';

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: CustomerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Customer sign in'), findsOneWidget);
  });
}
