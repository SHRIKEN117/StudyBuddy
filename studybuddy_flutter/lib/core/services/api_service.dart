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
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _parse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final msg = body['error'] as String? ?? 'Request failed';
      throw ApiException(msg, response.statusCode);
    }
    return body;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return _parse(response);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return _parse(response);
  }

  static Future<Map<String, dynamic>> uploadFile(
    String path,
    File file,
    String fieldName,
  ) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}$path'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: MediaType('application', 'pdf'),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parse(response);
  }
}
