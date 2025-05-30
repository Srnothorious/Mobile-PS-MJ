// Importa Flutter UI
import 'package:flutter/material.dart';
// Importa tema personalizado
import 'presentation/themes/app_themes.dart';
// Importa tela de splash
import 'screens/splash_screen.dart';
// Importa configuração de localização
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const TodoApp()); // Inicia o app
}

// Widget principal do aplicativo
class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

// Estado do aplicativo que controla tema
class _TodoAppState extends State<TodoApp> {
  bool isDarkMode = false; // Controle do tema atual

  // Alterna entre tema claro e escuro
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false, // Remove a flag DEBUG
      theme: AppThemes.lightTheme, // Tema claro
      darkTheme: AppThemes.darkTheme, // Tema escuro
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Configuração de localização em português brasileiro
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português brasileiro
      ],

      home: SplashScreen(toggleTheme: toggleTheme), // Tela inicial
    );
  }
}
