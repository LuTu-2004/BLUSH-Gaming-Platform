import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Base URL kết nối tới Backend ASP.NET Core Web API (.NET 8)
  // Khi chạy trên Android Emulator: dùng http://10.0.2.2:5000/api
  // Khi chạy trên Máy thật: dùng IP Wi-Fi máy chạy .NET (VD: http://192.168.1.5:5000/api)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
  }
}
