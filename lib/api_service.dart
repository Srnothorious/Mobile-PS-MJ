// Importa a biblioteca para manipular JSON
import 'dart:convert';
// Importa pacote HTTP para requisições
import 'package:http/http.dart' as http;
// Importa modelo Task
import 'models/task.dart';
// Importa helper para logs condicionais
import 'helpers/api_helper.dart';

// Serviço API para autenticação e CRUD de tarefas
class ApiService {
  static const String baseUrl = 'http://localhost:3000/'; // URL base da API

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

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMessage = ApiHelper.extractErrorMessage(response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      ApiHelper.debugLog('Erro em updateTask: $e');
      rethrow;
    }
  }

  // Exclui tarefa por ID
  static Future<void> deleteTask(String token, String id) async {
    await http.delete(
      Uri.parse('${baseUrl}tasks/$id'), // Endpoint de exclusão
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Exclui todas as tarefas marcadas como concluídas
  static Future<void> deleteDoneTasks(String token) async {
    await http.delete(
      Uri.parse('${baseUrl}tasks?completed=true'), // Filtro de concluídas
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
