// Importa o pacote Flutter com widgets básicos de UI
import 'package:flutter/material.dart';
// Importa a tela de login
import 'screens/login_screen.dart';
// Importa definições de tema claro e escuro
import 'theme.dart';

// Função principal do app
void main() {
  runApp(MyApp()); // Executa o widget principal
}

// Widget principal que mantém estado (para alternar tema)
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState(); // Cria estado interno
}

// Estado do widget principal
class _MyAppState extends State<MyApp> {
  bool isDark = false; // Controle do modo escuro

  // Método para alternar tema
  void toggleTheme() {
    setState(() => isDark = !isDark); // Inverte valor e refaz UI
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sr. Jubileu', // Título do aplicativo
      theme: isDark ? darkTheme : lightTheme, // Escolhe tema
      home: LoginScreen(toggleTheme: toggleTheme), // Tela inicial
      debugShowCheckedModeBanner: false, // Remove banner de debug
    );
  }
}
