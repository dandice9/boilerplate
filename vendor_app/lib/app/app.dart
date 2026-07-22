import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../shared/providers/auth_provider.dart';

class VendorApp extends ConsumerWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Vendor App',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: auth.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (auth.isAuthenticated ? const DashboardPage() : const LoginPage()),
    );
  }
}
