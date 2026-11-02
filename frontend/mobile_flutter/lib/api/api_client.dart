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
  bool get isTwoFactorRequired => code == 'TWO_FACTOR_REQUIRED';

  @override
  String toString() => message;
}

/// Gọi REST API tới backend ASP.NET Core.
/// Tự gắn header "Authorization: Bearer <token>" khi đã đăng nhập.
class ApiClient {
  final http.Client _http;
  final String baseUrl;
  String? accessToken;

  /// Gọi khi request ĐÃ gắn token mà backend trả 401 (token hết hạn, tài khoản bị khóa / đổi vai trò).
  /// AuthService dùng để tự đăng xuất về màn đăng nhập.
  void Function()? onUnauthorized;

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

  Future<dynamic> delete(String endpoint) => _send(() => _http.delete(_uri(endpoint), headers: _headers));

  /// Gửi 1 file dạng multipart/form-data (VD ảnh đại diện), trường tên [field]
  Future<dynamic> postFile(String endpoint, {required String field, required List<int> bytes, required String filename}) => _send(() async {
        final request = http.MultipartRequest('POST', _uri(endpoint))
          ..headers['Accept'] = 'application/json'
          ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
        if (accessToken != null) request.headers['Authorization'] = 'Bearer $accessToken';
        return http.Response.fromStream(await _http.send(request));
      });

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

    // Lỗi 500 ở chế độ dev trả trang lỗi dạng chữ, không phải JSON -> coi như không có nội dung
    // (để rơi xuống ApiException bên dưới; màn hình chỉ bắt ApiException, FormatException lọt ra thì quay vòng mãi)
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    dynamic data;
    try {
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw ApiException('Máy chủ trả dữ liệu không hợp lệ, vui lòng thử lại.', statusCode: response.statusCode);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    if (response.statusCode == 401 && accessToken != null) onUnauthorized?.call();
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
    if (statusCode >= 500) return 'Máy chủ đang gặp lỗi, vui lòng thử lại sau.';
    return 'Có lỗi xảy ra (mã $statusCode).';
  }
}
