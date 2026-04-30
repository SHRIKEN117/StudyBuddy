import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 30);
  static const _aiTimeout = Duration(seconds: 120);
  static const _uploadTimeout = Duration(seconds: 60);
  static String _baseUrl = ApiConstants.baseUrl;
  static String? _cachedToken;

  // Persistent client enables TCP connection reuse (keep-alive) across requests.
  static final _client = http.Client();

  // AI endpoints need much more time for generation
  static Duration _timeoutFor(String path) =>
      path.startsWith('/ai/') ? _aiTimeout : _timeout;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server_url');
    if (saved != null && saved.isNotEmpty) _baseUrl = saved;
    // Pre-warm token cache at startup
    _cachedToken = prefs.getString('token');
  }

  static String get baseUrl => _baseUrl;

  static void cacheToken(String token) {
    _cachedToken = token;
  }

  static void clearToken() {
    _cachedToken = null;
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _baseUrl);
  }

  static Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    return _cachedToken;
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, String>> authHeaders() async {
    final headers = <String, String>{};
    final token = await _getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Map<String, dynamic> _parse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid server response', response.statusCode);
    }
    if (response.statusCode >= 400) {
      final msg = body['error'] as String? ?? 'Request failed';
      throw ApiException(msg, response.statusCode);
    }
    return body;
  }

  // Converts any low-level exception into a user-friendly ApiException.
  static Never _rethrow(Object e) {
    if (e is ApiException) throw e;
    if (e is SocketException) {
      throw ApiException(
        'Cannot reach server. Check your connection and make sure the backend is running.',
        0,
      );
    }
    if (e is TimeoutException) {
      throw ApiException('Request timed out. Please try again.', 408);
    }
    if (e is HandshakeException) {
      throw ApiException('SSL handshake failed.', 0);
    }
    throw ApiException('Unexpected error: ${e.toString()}', 0);
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: await _headers(),
          )
          .timeout(_timeoutFor(path));
      return _parse(response);
    } catch (e) {
      _rethrow(e);
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeoutFor(path));
      return _parse(response);
    } catch (e) {
      _rethrow(e);
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeoutFor(path));
      return _parse(response);
    } catch (e) {
      _rethrow(e);
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$_baseUrl$path'),
            headers: await _headers(),
          )
          .timeout(_timeoutFor(path));
      return _parse(response);
    } catch (e) {
      _rethrow(e);
    }
  }

  static Future<Map<String, dynamic>> uploadFile(
    String path,
    File file,
    String fieldName, {
    Map<String, String> fields = const {},
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$path'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: MediaType('application', 'pdf'),
      ));
      final streamed = await _client.send(request).timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } catch (e) {
      _rethrow(e);
    }
  }
}
