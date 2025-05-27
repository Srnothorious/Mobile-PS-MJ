// Importa essenciais do Flutter
import 'package:flutter/material.dart';
// Importa serviço API
import '../api_service.dart';
// Importa modelo Task
import '../models/task.dart';
// Importa tela de formulário de tarefa
import 'task_form_screen.dart';

// Tela principal que exibe a lista de tarefas
class TaskListScreen extends StatefulWidget {
  final String token;             // Token de autenticação
  final VoidCallback toggleTheme; // Função para alternar tema

  TaskListScreen({required this.token, required this.toggleTheme});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

// Estado da lista de tarefas
class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];      // Lista de tarefas carregadas
  bool isLoading = true;      // Controle de loading

  @override
  void initState() {
    super.initState();
    loadTasks();              // Carrega tarefas ao iniciar
  }

  // Carrega tarefas da API
  Future<void> loadTasks() async {
    setState(() => isLoading = true);    // Inicia indicador
    tasks = await ApiService.getTasks(widget.token); // Busca lista
    setState(() => isLoading = false);   // Finaliza indicador
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Tarefas'),               // Título
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),        // Ícone de limpar
            onPressed: () {
              ApiService.deleteDoneTasks(widget.token); // Exclui concluídas
              loadTasks();                            // Recarrega lista
            },
          ),
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,            // Alterna tema
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Indicador de loading
          : RefreshIndicator(
              onRefresh: loadTasks,                    // Pull-to-refresh
              child: ListView.builder(
                itemCount: tasks.length,               // Número de itens
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task.title),            // Título da tarefa
                    subtitle: Text(task.date),          // Data da tarefa
                    trailing: Checkbox(
                      value: task.done,                 // Status concluído
                      onChanged: (val) {
                        task.done = val!;               // Atualiza status
                        ApiService.updateTask(widget.token, task); // Salva
                        loadTasks();                    // Recarrega
                      },
                    ),
                    onTap: () async {
                      // Edita tarefa existente
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskFormScreen(
                            token: widget.token,
                            existing: task,
                          ),
                        ),
                      );
                      loadTasks();                       // Atualiza lista
                    },
                    onLongPress: () {
                      // Exclui tarefa ao pressionar longo
                      ApiService.deleteTask(widget.token, task.id!);
                      loadTasks();                       // Atualiza lista
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Cria nova tarefa
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(token: widget.token),
            ),
          );
          loadTasks(); // Atualiza lista
        },
        child: Icon(Icons.add), // Ícone de adicionar
      ),
    );
  }
}
