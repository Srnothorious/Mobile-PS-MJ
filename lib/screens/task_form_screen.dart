import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final String token; // Token de autenticação
  final Task? existing; // Tarefa existente para edição

  TaskFormScreen({required this.token, this.existing});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final titleController = TextEditingController(); // Controller título
  final descriptionController = TextEditingController(); // Controller descrição
  final dateController = TextEditingController(); // Controller data
  String priority = 'baixa'; // Prioridade padrão

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      // Se editando tarefa
      titleController.text = widget.existing!.title; // Preenche título
      descriptionController.text =
          widget.existing!.description; // Preenche descrição
      dateController.text =
          widget.existing!.date; // Preenche data (já no formato ISO esperado)
      priority = widget.existing!.priority; // Preenche prioridade
    }
  }

  // Salva tarefa (cria ou atualiza)
  void saveTask() {
    final task = Task(
      id: widget.existing?.id, // Mantém ID se existir (edição)
      title: titleController.text, // Título
      description: descriptionController.text, // Descrição
      date: dateController.text, // Data/hora em ISO 8601
      priority: priority, // Prioridade
      done: widget.existing?.done ?? false, // Status concluído
    );
    if (widget.existing == null) {
      ApiService.createTask(widget.token, task); // Cria tarefa
    } else {
      ApiService.updateTask(widget.token, task); // Atualiza tarefa
    }
    Navigator.pop(context); // Volta para a tela anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // Espaçamento interno
        child: Column(
          children: [
            TextField(
              controller: titleController, // Campo título
              decoration: InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descriptionController, // Campo descrição
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: dateController, // Campo data/hora
              readOnly: true, // Desabilita digitação manual
              decoration: InputDecoration(
                labelText: 'Data e Hora',
                suffixIcon: Icon(
                  Icons.calendar_today,
                ), // Ícone para indicar seletor
              ),
              onTap: () async {
                // Abre seletor de data
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate == null) return; // Se cancelou, sai

                // Abre seletor de hora
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime == null) return; // Se cancelou, sai

                // Combina data e hora escolhidas
                final combined = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );

                // Converte para UTC e formato ISO 8601 (ex: 2025-12-25T00:00:00.000Z)
                final isoString = combined.toUtc().toIso8601String();

                // Atualiza o campo com a data formatada
                setState(() {
                  dateController.text = isoString;
                });
              },
            ),
            DropdownButton<String>(
              value: priority, // Prioridade selecionada
              items:
                  ['baixa', 'média', 'alta']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) => setState(() => priority = val!),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTask, // Botão salvar tarefa
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
