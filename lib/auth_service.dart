import 'package:flutter/material.dart';
import 'auth_storage.dart';
import 'token_manager.dart';
import 'api_service.dart';
import 'screens/login_screen.dart';

class AuthService {
  static BuildContext? _context;
  static VoidCallback? _toggleTheme;

  // Configura o contexto global para logout
  static void configure(BuildContext context, VoidCallback toggleTheme) {
    _context = context;
    _toggleTheme = toggleTheme;

    // Configura callback no ApiService
    ApiService.setOnTokenExpiredCallback(_handleTokenExpired);
  }

  // Remove configuração quando sai do app
  static void dispose() {
    _context = null;
    _toggleTheme = null;
    ApiService.clearOnTokenExpiredCallback();
  }

  // Manipula token expirado - logout automático
  static void _handleTokenExpired() async {
    if (_context == null || _toggleTheme == null) return;

    // Limpa dados locais
    TokenManager.instance.dispose();
    await AuthStorage.clearLoginData();

    // Mostra mensagem de sessão expirada
    if (_context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Navega para tela de login
      Navigator.pushAndRemoveUntil(
        _context!,
        MaterialPageRoute(
          builder: (context) => LoginScreen(toggleTheme: _toggleTheme!),
        ),
        (route) => false, // Remove todas as rotas anteriores
      );
    }
  }

  // Logout manual (usado pelos botões de sair)
  static Future<void> logout() async {
    TokenManager.instance.dispose();
    await AuthStorage.clearLoginData();

    if (_context != null && _toggleTheme != null && _context!.mounted) {
      Navigator.pushAndRemoveUntil(
        _context!,
        MaterialPageRoute(
          builder: (context) => LoginScreen(toggleTheme: _toggleTheme!),
        ),
        (route) => false,
      );
    }
  }
}
