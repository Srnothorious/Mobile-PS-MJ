import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final String token; // Token de autenticação
  final Task? existing; // Tarefa existente para edição

  const TaskFormScreen({super.key, required this.token, this.existing});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final titleController = TextEditingController(); // Controller título
  final descriptionController = TextEditingController(); // Controller descrição
  final dateController = TextEditingController(); // Controller data
  String priority = 'baixa'; // Prioridade padrão
  String? originalIsoDate; // Armazena a data ISO original

  // Formata data ISO para formato "Dia/Mes/Ano às Hora"
  String formatDateForDisplay(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      final date =
          '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$date às $time';
    } catch (e) {
      return isoDate; // Retorna original se houver erro
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      // Se editando tarefa
      titleController.text = widget.existing!.title; // Preenche título
      descriptionController.text =
          widget.existing!.description; // Preenche descrição
      originalIsoDate = widget.existing!.date; // Armazena ISO original
      dateController.text = formatDateForDisplay(
          widget.existing!.date); // Preenche data formatada
      priority = widget.existing!.priority; // Preenche prioridade
    }
  }

  // Salva tarefa (cria ou atualiza)
  void saveTask() async {
    try {
      // Validações
      if (titleController.text.trim().isEmpty) {
        throw Exception('Título é obrigatório');
      }

      if (originalIsoDate == null || originalIsoDate!.isEmpty) {
        throw Exception('Data e hora são obrigatórias');
      }

      final task = Task(
        id: widget.existing?.id, // Mantém ID se existir (edição)
        title: titleController.text.trim(), // Título
        description: descriptionController.text.trim(), // Descrição
        date: originalIsoDate!, // Data/hora em ISO 8601
        priority: priority, // Prioridade
        completed: widget.existing?.completed ?? false, // Status concluído
      );

      print('Salvando tarefa: ${task.toJson()}');

      if (widget.existing == null) {
        await ApiService.createTask(widget.token, task); // Cria tarefa
        print('Tarefa criada com sucesso');
      } else {
        await ApiService.updateTask(widget.token, task); // Atualiza tarefa
        print('Tarefa atualizada com sucesso');
      }

      if (mounted) {
        Navigator.pop(context); // Volta para a tela anterior
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Erro ao salvar tarefa: $errorMessage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $errorMessage')),
        );
      }
    }
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
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descriptionController, // Campo descrição
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: dateController, // Campo data/hora
              readOnly: true, // Desabilita digitação manual
              decoration: const InputDecoration(
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

                if (pickedDate == null || !mounted) {
                  return; // Se cancelou ou widget desmontado, sai
                }

                // Abre seletor de hora
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime == null || !mounted) {
                  return; // Se cancelou ou widget desmontado, sai
                }

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
                  originalIsoDate = isoString; // Armazena ISO original
                  dateController.text = formatDateForDisplay(isoString);
                });
              },
            ),
            DropdownButton<String>(
              value: priority, // Prioridade selecionada
              items: ['baixa', 'média', 'alta']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => priority = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTask, // Botão salvar tarefa
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
