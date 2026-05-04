import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    final v = dotenv.env['API_BASE_URL'];
    if (v == null || v.trim().isEmpty) {
      throw StateError('API_BASE_URL is missing. Add it to your .env file.');
    }
    return v.trim();
  }
}

