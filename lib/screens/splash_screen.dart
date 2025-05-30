import 'package:flutter/material.dart';
import '../auth_storage.dart';
import '../token_manager.dart';
import 'login_screen.dart';
import 'task_list_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const SplashScreen({super.key, required this.toggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Aguarda um pouco para mostrar a splash
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Verifica se tem token salvo e se é válido
      final token = await AuthStorage.getSavedToken();
      final isValid = await AuthStorage.isTokenValid();

      if (token != null && isValid && mounted) {
        // Token existe e é válido - inicializa TokenManager e vai para TaskList
        TokenManager.instance.initialize(
          token: token,
          onTokenRefreshed: (newToken) {
            // Token renovado automaticamente
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Token renovado automaticamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onTokenExpired: () {
            // Token expirou - volta para login
            if (mounted) {
              TokenManager.instance.dispose();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LoginScreen(toggleTheme: widget.toggleTheme),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sessão expirada. Faça login novamente.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(
              token: token,
              toggleTheme: widget.toggleTheme,
            ),
          ),
        );
      } else {
        // Não tem token válido - vai para login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LoginScreen(toggleTheme: widget.toggleTheme),
            ),
          );
        }
      }
    } catch (e) {
      // Erro na verificação - limpa dados e vai para login
      await AuthStorage.clearLoginData();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(toggleTheme: widget.toggleTheme),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou ícone do app
              Icon(
                Icons.task_alt,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),

              // Nome do app
              Text(
                'Todo App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),

              // Indicador de loading
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),

              Text(
                'Verificando autenticação...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
