import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiHelper {
  // Log condicional (apenas em desenvolvimento)
  static void debugLog(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // Extrai mensagens de erro do JSON de resposta
  static String extractErrorMessage(String responseBody) {
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
