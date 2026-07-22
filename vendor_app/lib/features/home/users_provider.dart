import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user.dart';
import '../../shared/providers/api_client.dart';

final usersProvider = FutureProvider<List<User>>((ref) async {
  final client = ref.watch(httpClientProvider);
  final response = await client.get(Uri.parse('$apiBaseUrl/users'));

  if (response.statusCode != 200) {
    throw Exception('Failed to load users (${response.statusCode})');
  }

  final data = jsonDecode(response.body) as List<dynamic>;
  return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
});
