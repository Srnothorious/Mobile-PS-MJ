// Importa Flutter UI
import 'package:flutter/material.dart';
// Importa serviço API
import '../api_service.dart';
// Importa tela de lista de tarefas
import 'task_list_screen.dart';
// Importa gerenciador de tokens
import '../token_manager.dart';
// Importa storage de autenticação
import '../auth_storage.dart';

// Tela de login
class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme; // Função para alternar tema
  const LoginScreen({super.key, required this.toggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Estado da tela de login
class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController(); // Controller do e-mail
  final passwordController = TextEditingController(); // Controller da senha
  bool isLoading = false;
  bool keepLoggedIn = false; // Checkbox continuar logado

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  // Carrega email salvo se existir
  Future<void> _loadSavedEmail() async {
    final savedEmail = await AuthStorage.getSavedEmail();
    final shouldKeepLoggedIn = await AuthStorage.shouldKeepLoggedIn();

    if (savedEmail != null) {
      emailController.text = savedEmail;
      setState(() {
        keepLoggedIn = shouldKeepLoggedIn;
      });
    }
  }

  // Função de login
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await ApiService.login(
        emailController.text, // Passa valor do e-mail
        passwordController.text, // Passa valor da senha
      );

      if (token != null && context.mounted) {
        // Salva dados de login conforme escolha do usuário
        await AuthStorage.saveLoginData(
          token: token,
          email: emailController.text,
          keepLoggedIn: keepLoggedIn,
        );

        // Inicializa o gerenciador de tokens
        TokenManager.instance.initialize(
          token: token,
          onTokenRefreshed: (newToken) {
            // Token foi renovado automaticamente
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Token renovado automaticamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onTokenExpired: () {
            // Token expirou e não pôde ser renovado - força logout
            if (context.mounted) {
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'), // Título da AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme, // Alterna tema
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // Espaçamento interno
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController, // Vincula controller
              decoration: const InputDecoration(labelText: 'E-mail'), // Rótulo
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24), // Espaço vertical aumentado
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true, // Oculta texto
            ),
            const SizedBox(height: 16),

            // Checkbox "Continuar logado"
            Row(
              children: [
                Checkbox(
                  value: keepLoggedIn,
                  onChanged: (value) {
                    setState(() {
                      keepLoggedIn = value ?? false;
                    });
                  },
                ),
                const Text('Continuar logado'),
              ],
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : login, // Desabilita durante loading
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'), // Mostra loading ou texto
            ),
          ],
        ),
      ),
    );
  }
}
