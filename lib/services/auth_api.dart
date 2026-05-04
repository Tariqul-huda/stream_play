import 'dart:convert';

import 'package:http/http.dart' as http;

import './auth_storage.dart';

class AuthApiException implements Exception {
  final String message;
  AuthApiException(this.message);

  @override
  String toString() => 'AuthApiException: $message';
}

class AuthResult {
  final String accessToken;
  final int expiresInSeconds;
  final String userId;
  final String email;

  const AuthResult({
    required this.accessToken,
    required this.expiresInSeconds,
    required this.userId,
    required this.email,
  });

  factory AuthResult.fromJson(Map<String, Object?> json) {
    return AuthResult(
      accessToken: (json['accessToken'] as String?) ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as int?) ?? 0,
      userId: (json['userId'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}

class SendOtpResult {
  final String message;
  final String? devOtp;

  const SendOtpResult({required this.message, this.devOtp});

  factory SendOtpResult.fromJson(Map<String, Object?> json) {
    return SendOtpResult(
      message: (json['message'] as String?) ?? 'OTP sent',
      devOtp: json['devOtp'] as String?,
    );
  }
}

class AuthApi {
  final String baseUrl;
  final http.Client _client;
  final AuthStorage _storage;

  AuthApi({
    required this.baseUrl,
    http.Client? client,
    AuthStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? AuthStorage();

  Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    final res = await _postJson(
      '/api/auth/register',
      body: {'email': email, 'password': password},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = _decodeJson(res);
      final result = AuthResult.fromJson(decoded);
      if (result.accessToken.isEmpty) {
        throw AuthApiException('Login token missing from response.');
      }
      await _storage.saveAccessToken(result.accessToken);
      return result;
    }
    throw AuthApiException(_errorMessage(res));
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _postJson(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = _decodeJson(res);
      final result = AuthResult.fromJson(decoded);
      if (result.accessToken.isEmpty) {
        throw AuthApiException('Login token missing from response.');
      }
      await _storage.saveAccessToken(result.accessToken);
      return result;
    }
    throw AuthApiException(_errorMessage(res));
  }

  Future<SendOtpResult> sendOtp({required String email}) async {
    final res = await _postJson(
      '/api/auth/send-otp',
      body: {'email': email},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = _decodeJson(res);
      return SendOtpResult.fromJson(decoded);
    }
    throw AuthApiException(_errorMessage(res));
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _postJson(
      '/api/auth/reset-password',
      body: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw AuthApiException(_errorMessage(res));
  }

  Future<http.Response> _postJson(
    String path, {
    required Map<String, Object?> body,
  }) async {
    try {
      return await _client.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } on http.ClientException catch (_) {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Map<String, Object?> _decodeJson(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    throw AuthApiException('Unexpected response.');
  }

  String _errorMessage(http.Response res) {
    // Prefer server-provided `{message: "..."}`
    try {
      final decoded = jsonDecode(res.body);

      // Handle ASP.NET Core validation errors (ProblemDetails)
      if (decoded is Map && decoded['errors'] is Map) {
        final errors = decoded['errors'] as Map;
        final errorMessages = <String>[];
        for (final key in errors.keys) {
          final value = errors[key];
          if (value is List && value.isNotEmpty) {
            errorMessages.add(value.first.toString());
          } else if (value is String) {
            errorMessages.add(value);
          }
        }
        if (errorMessages.isNotEmpty) {
          return errorMessages.join('\n');
        }
      }

      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {
      // ignore
    }

    if (res.statusCode == 400) return 'Invalid request. Please check and try again.';
    if (res.statusCode == 401) return 'Unauthorized.';
    if (res.statusCode == 404) return 'Service not found.';
    if (res.statusCode == 429) return 'Too many attempts. Please wait and try again.';
    if (res.statusCode >= 500) return 'Server error. Please try again later.';
    return 'Request failed (${res.statusCode}).';
  }
}

