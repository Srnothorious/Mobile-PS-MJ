// Importa widgets Flutter
import 'package:flutter/material.dart';
// Importa serviço API
import '../api_service.dart';
// Importa modelo Task
import '../models/task.dart';

// Tela para criar ou editar tarefa
class TaskFormScreen extends StatefulWidget {
  final String token;        // Token de autenticação
  final Task? existing;      // Tarefa existente para edição

  TaskFormScreen({required this.token, this.existing});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

// Estado da tela de formulário
class _TaskFormScreenState extends State<TaskFormScreen> {
  final titleController = TextEditingController();       // Controller título
  final descriptionController = TextEditingController(); // Controller descrição
  final dateController = TextEditingController();        // Controller data
  String priority = 'baixa';                             // Prioridade padrão

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {                      // Se editando
      titleController.text = widget.existing!.title;     // Preenche campos
      descriptionController.text = widget.existing!.description;
      dateController.text = widget.existing!.date;
      priority = widget.existing!.priority;
    }
  }

  // Salva tarefa (cria ou atualiza)
  void saveTask() {
    final task = Task(
      id: widget.existing?.id,        // Mantém ID se existir
      title: titleController.text,
      description: descriptionController.text,
      date: dateController.text,
      priority: priority,
      done: widget.existing?.done ?? false,
    );
    if (widget.existing == null) {
      ApiService.createTask(widget.token, task); // Cria
    } else {
      ApiService.updateTask(widget.token, task); // Atualiza
    }
    Navigator.pop(context); // Volta para lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // Espaço interno
        child: Column(
          children: [
            TextField(
              controller: titleController,  // Título
              decoration: InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Data'),
            ),
            DropdownButton<String>(
              value: priority,             // Valor selecionado
              items: ['baixa', 'média', 'alta']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),            // Itens de prioridade
              onChanged: (val) => setState(() => priority = val!), // Atualiza
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTask,        // Chama salvar
              child: Text('Salvar'),       // Rótulo
            ),
          ],
        ),
      ),
    );
  }
}
