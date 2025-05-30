// Tela de detalhes da tarefa
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/task.dart';
import '../api_service.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final String token;

  const TaskDetailScreen({super.key, required this.task, required this.token});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task currentTask;
  bool hasChanges = false; // Flag para indicar se houve mudanças

  @override
  void initState() {
    super.initState();
    currentTask = widget.task;
  }

  // Recarrega a tarefa atual
  Future<void> refreshTask() async {
    final tasks = await ApiService.getTasks(widget.token);
    final updatedTask = tasks.firstWhere((t) => t.id == currentTask.id);
    setState(() {
      currentTask = updatedTask;
    });
  }

  // Faz parse manual da ISO-8601 sem conversões de timezone
  DateTime _parseIsoWithoutTimezoneConversion(String isoDate) {
    // Remove timezone para evitar conversão automática
    final withoutTimezone =
        isoDate.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$|Z$'), '');
    return DateTime.parse(withoutTimezone);
  }

  // Verifica se a tarefa foi concluída em atraso
  bool isCompletedLate() {
    if (!currentTask.completed) return false;

    final taskDate = _parseIsoWithoutTimezoneConversion(currentTask.date);
    final now = DateTime.now();

    return taskDate.isBefore(now);
  }

  // Formata data ISO para formato brasileiro
  String formatDate(String isoDate) {
    try {
      // Parse manual sem conversão de timezone
      final dateTime = _parseIsoWithoutTimezoneConversion(isoDate);
      return DateFormat('dd/MM/yyyy \'às\' HH:mm').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  // Confirma exclusão de tarefa
  Future<void> confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            Text('Deseja realmente excluir a tarefa "${currentTask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.deleteTask(widget.token, currentTask.id!);
      if (context.mounted) {
        Navigator.pop(
            context, true); // Retorna true para indicar que foi excluída
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Retorna true para TaskListScreen se houve mudanças
          Navigator.pop(context, hasChanges);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes da Tarefa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => confirmDelete(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card do título e status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTask.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: currentTask.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentTask.completed
                              ? (isCompletedLate()
                                  ? Colors.orange
                                  : Colors.green)
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentTask.completed
                                  ? (isCompletedLate()
                                      ? 'Concluída em Atraso'
                                      : 'Concluída')
                                  : 'Pendente',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (currentTask.completed && isCompletedLate()) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Card da descrição
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descrição',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(currentTask.description),
                    ],
                  ),
                ),
              ),

              // Card das informações
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data limite: ${formatDate(currentTask.date)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: currentTask.priority == 'alta'
                                ? Colors.red
                                : currentTask.priority == 'media'
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prioridade: ${currentTask.priority}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mensagem informativa para tarefas concluídas
              if (currentTask.completed)
                Card(
                  color: Colors.green.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tarefa concluída! Para editar, marque como pendente primeiro.',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Botões de ação lado a lado
              Row(
                children: [
                  // Botão de editar (só se não estiver concluída)
                  if (!currentTask.completed)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskFormScreen(
                                  token: widget.token, existing: currentTask),
                            ),
                          );
                          // Se houve alteração, atualiza a task local e marca para atualizar a lista pai
                          if (result == true && context.mounted) {
                            // Busca a tarefa atualizada
                            await refreshTask();
                            // Marca que houve mudanças para atualizar a lista quando sair
                            hasChanges = true;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),

                  // Espaçamento entre botões se ambos estiverem visíveis
                  if (!currentTask.completed) const SizedBox(width: 12),

                  // Botão de alternar status
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                          currentTask.completed ? Icons.undo : Icons.check,
                          size: 18),
                      label: Text(currentTask.completed
                          ? 'Marcar como Pendente'
                          : 'Marcar como Concluída'),
                      onPressed: () async {
                        try {
                          final newStatus = !currentTask.completed;

                          // Usa método específico para atualizar apenas status
                          await ApiService.updateTaskStatus(
                              widget.token, currentTask.id!, newStatus);

                          if (context.mounted) {
                            // Atualiza a tarefa local e marca que houve mudanças
                            await refreshTask();
                            hasChanges = true;

                            // Feedback especial para conclusão em atraso
                            if (newStatus && isCompletedLate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.schedule, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Tarefa concluída em atraso!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade600,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao atualizar status: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentTask.completed
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
