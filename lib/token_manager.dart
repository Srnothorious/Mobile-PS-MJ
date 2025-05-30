import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'auth_storage.dart';

class TokenManager {
  static TokenManager? _instance;
  static TokenManager get instance => _instance ??= TokenManager._();

  TokenManager._();

  Timer? _refreshTimer;
  String? _currentToken;
  DateTime? _tokenCreatedAt;
  Function(String)? _onTokenRefreshed;
  VoidCallback? _onTokenExpired;

  // Configura o gerenciador de tokens
  void initialize({
    required String token,
    required Function(String) onTokenRefreshed,
    required VoidCallback onTokenExpired,
  }) {
    _currentToken = token;
    _tokenCreatedAt = DateTime.now();
    _onTokenRefreshed = onTokenRefreshed;
    _onTokenExpired = onTokenExpired;

    _scheduleTokenRefresh();
  }

  // Agenda o refresh do token para 6 dias
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();

    // Refresh a cada 6 dias (518400 segundos)
    const refreshInterval = Duration(days: 6);

    _refreshTimer = Timer(refreshInterval, () async {
      await _performTokenRefresh();
    });

    if (kDebugMode) {
      print(
          'Token refresh agendado para: ${DateTime.now().add(refreshInterval)}');
    }
  }

  // Executa o refresh do token
  Future<void> _performTokenRefresh() async {
    if (_currentToken == null) return;

    try {
      if (kDebugMode) {
        print('Iniciando refresh automático do token...');
      }

      final newToken = await ApiService.refreshToken(_currentToken!);

      if (newToken != null) {
        _currentToken = newToken;
        _tokenCreatedAt = DateTime.now();

        // Atualiza token no storage se estiver mantendo login
        await AuthStorage.updateToken(newToken);

        // Notifica que o token foi renovado
        _onTokenRefreshed?.call(newToken);

        // Agenda o próximo refresh
        _scheduleTokenRefresh();

        if (kDebugMode) {
          print('Token renovado com sucesso!');
        }
      } else {
        throw Exception('Token refresh retornou null');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro no refresh automático do token: $e');
      }

      // Token expirado ou erro crítico - limpa storage e notifica logout
      await AuthStorage.clearLoginData();
      _onTokenExpired?.call();
    }
  }

  // Força um refresh manual do token
  Future<String?> forceRefresh() async {
    if (_currentToken == null) return null;

    try {
      final newToken = await ApiService.refreshToken(_currentToken!);

      if (newToken != null) {
        _currentToken = newToken;
        _tokenCreatedAt = DateTime.now();

        // Atualiza token no storage
        await AuthStorage.updateToken(newToken);

        _onTokenRefreshed?.call(newToken);
        _scheduleTokenRefresh(); // Reagenda
        return newToken;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro no refresh manual: $e');
      }
      await AuthStorage.clearLoginData();
      _onTokenExpired?.call();
    }

    return null;
  }

  // Atualiza o token atual (quando faz login)
  void updateToken(String newToken) {
    _currentToken = newToken;
    _tokenCreatedAt = DateTime.now();
    _scheduleTokenRefresh();
  }

  // Para todos os timers (quando faz logout)
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _currentToken = null;
    _tokenCreatedAt = null;
    _onTokenRefreshed = null;
    _onTokenExpired = null;
  }

  // Getters para informações do token
  String? get currentToken => _currentToken;
  DateTime? get tokenCreatedAt => _tokenCreatedAt;

  // Verifica se o token está próximo do vencimento (5 dias)
  bool get isTokenNearExpiry {
    if (_tokenCreatedAt == null) return true;

    final daysSinceCreation =
        DateTime.now().difference(_tokenCreatedAt!).inDays;
    return daysSinceCreation >= 5;
  }
}
