// Importa Flutter UI
import 'package:flutter/material.dart';
// Importa serviço API
import '../api_service.dart';
// Importa tela de lista de tarefas
import 'task_list_screen.dart';

// Tela de login
class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme; // Função para alternar tema
  LoginScreen({required this.toggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Estado da tela de login
class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();    // Controller do e-mail
  final passwordController = TextEditingController(); // Controller da senha

  // Função de login
  void _login() async {
    final token = await ApiService.login(
      emailController.text,       // Passa valor do e-mail
      passwordController.text,    // Passa valor da senha
    );
    if (token != null) {
      // Navega para lista de tarefas ao logar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TaskListScreen(
            token: token,
            toggleTheme: widget.toggleTheme,
          ),
        ),
      );
    } else {
      // Exibe erro de senha ou usuário inválido
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha no login')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),    // Título da AppBar
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6), 
            onPressed: widget.toggleTheme, // Alterna tema
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // Espaçamento interno
        child: Column(
          children: [
            TextField(
              controller: emailController,    // Vincula controller
              decoration: InputDecoration(labelText: 'E-mail'), // Rótulo
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,             // Oculta texto
            ),
            SizedBox(height: 20),            // Espaço vertical
            ElevatedButton(
              onPressed: _login,            // Chama função de login
              child: Text('Entrar'),        // Rótulo do botão
            ),
          ],
        ),
      ),
    );
  }
}
