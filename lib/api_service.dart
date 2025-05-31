import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data/models/task.dart';
import 'helpers/api_helper.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/';

  static void Function()? _onTokenExpired;

  static void setOnTokenExpiredCallback(void Function() callback) {
    _onTokenExpired = callback;
  }

  static void clearOnTokenExpiredCallback() {
    _onTokenExpired = null;
  }

  static void _checkTokenExpiration(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      ApiHelper.debugLog('Token expirado detectado: ${response.statusCode}');
      _onTokenExpired?.call();
    }
  }

  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
    return null;
  }

  static Future<List<Task>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('${baseUrl}tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    _checkTokenExpiration(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar tarefas');
  }

  static Future<void> createTask(String token, Task task) async {
    try {
      const url = '${baseUrl}tasks';
      final body = jsonEncode(task.toJson());

      ApiHelper.debugLog('POST $url');
      ApiHelper.debugLog('Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      ApiHelper.debugLog('Response Status: ${response.statusCode}');
      ApiHelper.debugLog('Response Body: ${response.body}');

      _checkTokenExpiration(response);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMessage = ApiHelper.extractErrorMessage(response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      ApiHelper.debugLog('Erro em createTask: $e');
      rethrow;
    }
  }

  static Future<void> updateTask(String token, Task task) async {
    try {
      final url = '${baseUrl}tasks/${task.id}';
      final body = jsonEncode(task.toJson());

      ApiHelper.debugLog('PUT $url');
      ApiHelper.debugLog('Body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      ApiHelper.debugLog('Response Status: ${response.statusCode}');
      ApiHelper.debugLog('Response Body: ${response.body}');

      _checkTokenExpiration(response);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMessage = ApiHelper.extractErrorMessage(response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      ApiHelper.debugLog('Erro em updateTask: $e');
      rethrow;
    }
  }

  static Future<void> updateTaskStatus(
      String token, String taskId, bool completed) async {
    try {
      final url = '${baseUrl}tasks/$taskId';
      final body = jsonEncode({'completed': completed});

      ApiHelper.debugLog('PUT $url');
      ApiHelper.debugLog('Body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      ApiHelper.debugLog('Response Status: ${response.statusCode}');
      ApiHelper.debugLog('Response Body: ${response.body}');

      _checkTokenExpiration(response);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMessage = ApiHelper.extractErrorMessage(response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      ApiHelper.debugLog('Erro em updateTaskStatus: $e');
      rethrow;
    }
  }

  static Future<void> deleteTask(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}tasks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    _checkTokenExpiration(response);
  }

  static Future<void> deleteDoneTasks(String token) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}tasks?completed=true'),
      headers: {'Authorization': 'Bearer $token'},
    );

    _checkTokenExpiration(response);
  }

  static Future<String?> refreshToken(String currentToken) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}users/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      ApiHelper.debugLog('POST ${baseUrl}users/refresh');
      ApiHelper.debugLog('Response Status: ${response.statusCode}');
      ApiHelper.debugLog('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] as String?;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao renovar token');
      }
    } catch (e) {
      ApiHelper.debugLog('Erro no refresh do token: $e');
      throw Exception('Erro ao renovar token: $e');
    }
  }
}
