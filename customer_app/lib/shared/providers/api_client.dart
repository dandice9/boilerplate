import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'http://localhost:3000';

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
