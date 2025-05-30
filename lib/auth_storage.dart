import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _tokenCreatedAtKey = 'token_created_at';
  static const String _keepLoggedInKey = 'keep_logged_in';
  static const String _emailKey = 'user_email';

  // Salva dados de login
  static Future<void> saveLoginData({
    required String token,
    required String email,
    required bool keepLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (keepLoggedIn) {
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_emailKey, email);
      await prefs.setString(
          _tokenCreatedAtKey, DateTime.now().toIso8601String());
      await prefs.setBool(_keepLoggedInKey, true);
    } else {
      // Se não marcou "continuar logado", limpa dados salvos
      await clearLoginData();
    }
  }

  // Recupera token salvo
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final keepLoggedIn = prefs.getBool(_keepLoggedInKey) ?? false;

    if (!keepLoggedIn) return null;

    return prefs.getString(_tokenKey);
  }

  // Recupera email salvo
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Recupera data de criação do token
  static Future<DateTime?> getTokenCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_tokenCreatedAtKey);

    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  // Verifica se deve manter logado
  static Future<bool> shouldKeepLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepLoggedInKey) ?? false;
  }

  // Verifica se o token salvo ainda é válido (menos de 7 dias)
  static Future<bool> isTokenValid() async {
    final tokenCreatedAt = await getTokenCreatedAt();
    if (tokenCreatedAt == null) return false;

    final daysSinceCreation = DateTime.now().difference(tokenCreatedAt).inDays;
    return daysSinceCreation < 7; // Token válido por 7 dias
  }

  // Limpa todos os dados de login
  static Future<void> clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_tokenCreatedAtKey);
    await prefs.remove(_keepLoggedInKey);
  }

  // Atualiza apenas o token (para refresh)
  static Future<void> updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    final keepLoggedIn = prefs.getBool(_keepLoggedInKey) ?? false;

    if (keepLoggedIn) {
      await prefs.setString(_tokenKey, newToken);
      await prefs.setString(
          _tokenCreatedAtKey, DateTime.now().toIso8601String());
    }
  }
}
