// Importa a biblioteca para manipular JSON
import 'dart:convert';
// Importa pacote HTTP para requisições
import 'package:http/http.dart' as http;
// Importa modelo Task
import 'models/task.dart';

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
      print('POST ${baseUrl}tasks');
      print('Body: ${jsonEncode(task.toJson())}');

      final response = await http.post(
        Uri.parse('${baseUrl}tasks'), // Endpoint de criação
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson()), // Dados da tarefa em JSON
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMessage = _extractErrorMessage(response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro em createTask: $e');
      rethrow;
    }
  }

  // Atualiza tarefa existente
  static Future<void> updateTask(String token, Task task) async {
    try {
      print('PUT ${baseUrl}tasks/${task.id}');
      print('Body: ${jsonEncode(task.toJson())}');

      final response = await http.put(
        Uri.parse('${baseUrl}tasks/${task.id}'), // Endpoint com ID da tarefa
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson()), // Novos dados em JSON
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMessage = _extractErrorMessage(response.body);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro em updateTask: $e');
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

  // Extrai mensagens de erro do JSON de resposta
  static String _extractErrorMessage(String responseBody) {
    try {
      final errorJson = jsonDecode(responseBody);

      // Se há detalhes com mensagens específicas
      if (errorJson['details'] != null && errorJson['details'] is List) {
        final details = errorJson['details'] as List;
        final messages = details
            .where((detail) => detail['message'] != null)
            .map((detail) => detail['message'] as String)
            .toList();

        if (messages.isNotEmpty) {
          return messages.join(', ');
        }
      }

      // Se há uma mensagem de erro geral
      if (errorJson['error'] != null) {
        return errorJson['error'] as String;
      }

      // Se há uma mensagem simples
      if (errorJson['message'] != null) {
        return errorJson['message'] as String;
      }

      return 'Erro desconhecido';
    } catch (e) {
      // Se não conseguir parsear o JSON, retorna o corpo da resposta
      return responseBody;
    }
  }
}
