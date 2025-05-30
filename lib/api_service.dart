// Importa a biblioteca para manipular JSON
import 'dart:convert';
// Importa pacote HTTP para requisições
import 'package:http/http.dart' as http;
// Importa modelo Task
import 'data/models/task.dart';
// Importa helper para logs condicionais
import 'helpers/api_helper.dart';

// Serviço API para autenticação e CRUD de tarefas
class ApiService {
  static const String baseUrl = 'http://localhost:3000/'; // URL base da API

  // Callback global para logout quando token expira
  static void Function()? _onTokenExpired;

  // Configura callback de logout por token expirado
  static void setOnTokenExpiredCallback(void Function() callback) {
    _onTokenExpired = callback;
  }

  // Remove o callback (usado no dispose)
  static void clearOnTokenExpiredCallback() {
    _onTokenExpired = null;
  }

  // Interceptor para verificar se resposta indica token expirado
  static void _checkTokenExpiration(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      ApiHelper.debugLog('Token expirado detectado: ${response.statusCode}');
      _onTokenExpired?.call();
    }
  }

  // Envia credenciais para login e retorna token
  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}auth/login'), // Endpoint de login
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}), // Dados em JSON
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token']; // Retorna token se OK
    }
    return null; // Retorna null em caso de falha
  }

  // Busca lista de tarefas autorizadas pelo token
  static Future<List<Task>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('${baseUrl}tasks'), // Endpoint de lista
      headers: {'Authorization': 'Bearer $token'}, // Cabeçalho de auth
    );

    // Verifica se token expirou
    _checkTokenExpiration(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body); // Decodifica JSON
      return data.map((e) => Task.fromJson(e)).toList(); // Converte em Task
    }
    throw Exception('Erro ao carregar tarefas'); // Lança erro se falhar
  }

  // Cria nova tarefa na API
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

      // Verifica se token expirou
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

  // Atualiza tarefa existente
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

      // Verifica se token expirou
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

  // Atualiza apenas o status de conclusão da tarefa
  static Future<void> updateTaskStatus(
      String token, String taskId, bool completed) async {
    try {
      final url = '${baseUrl}tasks/$taskId';
      // Envia apenas o status - backend aceita objeto parcial
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

      // Verifica se token expirou
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

  // Exclui tarefa por ID
  static Future<void> deleteTask(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}tasks/$id'), // Endpoint de exclusão
      headers: {'Authorization': 'Bearer $token'},
    );

    // Verifica se token expirou
    _checkTokenExpiration(response);
  }

  // Exclui todas as tarefas marcadas como concluídas
  static Future<void> deleteDoneTasks(String token) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}tasks?completed=true'), // Filtro de concluídas
      headers: {'Authorization': 'Bearer $token'},
    );

    // Verifica se token expirou
    _checkTokenExpiration(response);
  }

  // Faz refresh do token
  static Future<String?> refreshToken(String currentToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      ApiHelper.debugLog('POST $baseUrl/auth/refresh');
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
