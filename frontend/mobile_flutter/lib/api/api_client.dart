import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Lỗi khi gọi API. [message] là câu tiếng Việt có thể hiện thẳng cho người dùng.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  /// Mã lỗi backend gửi kèm để app xử lý tiếp, VD: 'EMAIL_NOT_VERIFIED'
  final String? code;

  ApiException(this.message, {this.statusCode, this.code});

  bool get isUnauthorized => statusCode == 401;
  bool get isEmailNotVerified => code == 'EMAIL_NOT_VERIFIED';

  @override
  String toString() => message;
}

/// Gọi REST API tới backend ASP.NET Core.
/// Tự gắn header "Authorization: Bearer <token>" khi đã đăng nhập.
class ApiClient {
  final http.Client _http;
  final String baseUrl;
  String? accessToken;

  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  static const _timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<dynamic> get(String endpoint) => _send(() => _http.get(_uri(endpoint), headers: _headers));

  Future<dynamic> post(String endpoint, [Map<String, dynamic>? body]) => _send(
        () => _http.post(_uri(endpoint), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  Uri _uri(String endpoint) => Uri.parse('$baseUrl/$endpoint');

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại.');
    } catch (_) {
      throw ApiException('Không kết nối được máy chủ. Kiểm tra mạng hoặc backend đã chạy chưa.');
    }

    final text = utf8.decode(response.bodyBytes);
    final data = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ApiException(
      _errorMessage(response.statusCode, data),
      statusCode: response.statusCode,
      code: data is Map ? data['code'] as String? : null,
    );
  }

  // Backend trả lỗi dạng { "message": "..." } hoặc lỗi validation { "errors": { "Email": ["..."] } }
  static String _errorMessage(int statusCode, dynamic data) {
    if (data is Map) {
      if (data['message'] is String) return data['message'];
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    if (statusCode == 401) return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.';
    return 'Có lỗi xảy ra (mã $statusCode).';
  }
}
