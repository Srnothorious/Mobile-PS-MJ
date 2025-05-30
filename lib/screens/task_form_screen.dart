import 'package:flutter/material.dart';
import '../data/models/task.dart';
import '../api_service.dart';
import 'package:intl/intl.dart';

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
  String priority = 'baixa'; // Prioridade padrão
  DateTime selectedDateTime = DateTime.now(); // Data selecionada

  // Formata data para exibição em português brasileiro
  String formatDateForDisplay(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy \'às\' HH:mm').format(dateTime);
  }

  // Faz parse manual da ISO-8601 sem conversões de timezone
  DateTime _parseIsoWithoutTimezoneConversion(String isoDate) {
    // Remove timezone para evitar conversão automática
    final withoutTimezone =
        isoDate.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$|Z$'), '');
    return DateTime.parse(withoutTimezone);
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      // Se editando tarefa, preenche todos os campos corretamente
      titleController.text = widget.existing!.title;
      descriptionController.text = widget.existing!.description;
      priority = widget.existing!.priority;

      // Parse manual sem conversão de timezone
      try {
        selectedDateTime =
            _parseIsoWithoutTimezoneConversion(widget.existing!.date);
      } catch (e) {
        selectedDateTime = DateTime.now(); // Fallback se data inválida
      }
    }
  }

  // Salva ou atualiza a tarefa
  Future<void> saveTask() async {
    // Valida se há título
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título é obrigatório')),
      );
      return;
    }

    // FORMATO ISO-8601 COM TIMEZONE LOCAL (sem converter para UTC)
    final isoString = _buildIsoWithLocalTimezone(selectedDateTime);

    // Cria objeto Task com os dados
    final task = Task(
      id: widget.existing?.id,
      title: titleController.text,
      description: descriptionController.text,
      priority: priority,
      date: isoString, // ← ISO-8601 construída manualmente
      completed: widget.existing?.completed ?? false,
    );

    try {
      if (widget.existing == null) {
        await ApiService.createTask(widget.token, task);
      } else {
        await ApiService.updateTask(widget.token, task);
      }

      // Navegar de volta com sucesso
      if (context.mounted) {
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      // Mostra erro em caso de falha
      if (context.mounted) {
        // Remove "Exception:" da mensagem de erro
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar tarefa: $errorMessage')),
        );
      }
    }
  }

  // Constrói ISO-8601 com timezone local (preserva horário exato do usuário)
  String _buildIsoWithLocalTimezone(DateTime dateTime) {
    // Extrai componentes exatos sem conversão
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final millisecond = dateTime.millisecond.toString().padLeft(3, '0');

    // Monta data/hora exatamente como selecionada
    final dateTimePart =
        '$year-$month-${day}T$hour:$minute:$second.$millisecond';

    // Calcula offset do timezone local
    final offset = dateTime.timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = (offset.inMinutes % 60).abs();

    final sign = offsetHours >= 0 ? '+' : '-';
    final hoursStr = offsetHours.abs().toString().padLeft(2, '0');
    final minutesStr = offsetMinutes.toString().padLeft(2, '0');

    // Resultado: "2025-12-25T16:00:00.000-03:00" (horário local + timezone)
    return '$dateTimePart$sign$hoursStr:$minutesStr';
  }

  void pickDateTime() async {
    // VALIDAÇÃO: Data mínima é hoje (não permite datas passadas)
    final today = DateTime.now();
    final minimumDate = DateTime(today.year, today.month, today.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime.isBefore(minimumDate)
          ? minimumDate
          : selectedDateTime,
      firstDate: minimumDate, // ← Não permite datas anteriores a hoje
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'), // ← Calendário em português
      helpText: 'Selecionar data',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      helpText: 'Selecionar horário',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minuto',
      // CORRIGIDO: Permite ambos os modos (relógio visual + entrada manual)
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('pt', 'BR'), // ← Seletor de hora em português
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true, // ← Força formato 24h
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedDateTime = combined;
      // FORÇA ATUALIZAÇÃO: Garante que o campo visual sempre atualize
    });
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de título
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Título obrigatório' : null,
            ),
            const SizedBox(height: 20),

            // Campo de descrição
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Dropdown de prioridade
            DropdownButtonFormField<String>(
              value: priority,
              items: ['baixa', 'media', 'alta']
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => priority = value!),
              decoration: const InputDecoration(
                labelText: 'Prioridade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo de data/hora
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data e Hora',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: formatDateForDisplay(
                    selectedDateTime), // ← Sempre atualizado
              ),
              onTap: pickDateTime,
            ),
            const SizedBox(height: 32),

            // Botão de salvar
            ElevatedButton(
              onPressed: saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                widget.existing != null ? 'Atualizar Tarefa' : 'Criar Tarefa',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
