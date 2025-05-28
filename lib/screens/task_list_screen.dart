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
  final String token; // Token de autenticação
  final VoidCallback toggleTheme; // Função para alternar tema

  const TaskListScreen(
      {super.key, required this.token, required this.toggleTheme});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

// Estado da lista de tarefas
class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = []; // Lista de tarefas carregadas
  bool isLoading = true; // Controle de loading

  @override
  void initState() {
    super.initState();
    loadTasks(); // Carrega tarefas ao iniciar
  }

  // Formata data ISO para formato "Limite: {dia} de {mês}, {hora}"
  String formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      final months = [
        '',
        'janeiro',
        'fevereiro',
        'março',
        'abril',
        'maio',
        'junho',
        'julho',
        'agosto',
        'setembro',
        'outubro',
        'novembro',
        'dezembro'
      ];
      final day = dateTime.day;
      final month = months[dateTime.month];
      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return 'Limite: $day de $month, $time';
    } catch (e) {
      return isoDate; // Retorna original se houver erro
    }
  }

  // Carrega tarefas da API
  Future<void> loadTasks() async {
    setState(() => isLoading = true); // Inicia indicador
    tasks = await ApiService.getTasks(widget.token); // Busca lista
    setState(() => isLoading = false); // Finaliza indicador
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'), // Título
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever), // Ícone de limpar
            onPressed: () {
              ApiService.deleteDoneTasks(widget.token); // Exclui concluídas
              loadTasks(); // Recarrega lista
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme, // Alterna tema
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Indicador de loading
          : RefreshIndicator(
              onRefresh: loadTasks, // Pull-to-refresh
              child: ListView.builder(
                itemCount: tasks.length, // Número de itens
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task.title), // Título da tarefa
                    subtitle:
                        Text(formatDate(task.date)), // Data da tarefa formatada
                    trailing: Checkbox(
                      value: task.completed, // Status concluído
                      onChanged: (val) {
                        task.completed = val!; // Atualiza status
                        ApiService.updateTask(widget.token, task); // Salva
                        loadTasks(); // Recarrega
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
                      loadTasks(); // Atualiza lista
                    },
                    onLongPress: () {
                      // Exclui tarefa ao pressionar longo
                      ApiService.deleteTask(widget.token, task.id!);
                      loadTasks(); // Atualiza lista
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
        child: const Icon(Icons.add), // Ícone de adicionar
      ),
    );
  }
}
