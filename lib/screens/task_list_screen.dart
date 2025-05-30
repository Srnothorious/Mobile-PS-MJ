// Importa essenciais do Flutter
import 'package:flutter/material.dart';
// Importa serviço API
import '../api_service.dart';
// Importa modelo Task
import '../data/models/task.dart';
// Importa tela de formulário de tarefa
import 'task_form_screen.dart';
import 'package:intl/intl.dart';
import 'task_detail_screen.dart';
import '../token_manager.dart';
import '../auth_service.dart';

// Tela de listagem de tarefas com busca, filtros, ordenação e navegação adequada
class TaskListScreen extends StatefulWidget {
  final String token; // Token de autenticação
  final VoidCallback toggleTheme; // Função para alternar tema

  const TaskListScreen({
    super.key,
    required this.token,
    required this.toggleTheme,
  });

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

// Estado da lista de tarefas
class TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = []; // Lista original
  List<Task> filteredTasks = []; // Lista filtrada pela busca e filtros
  bool isLoading = true; // Controle de loading
  String sortOption = 'Padrão'; // Opção atual de ordenação
  String searchQuery = ''; // Texto da busca atual

  // Mapa de prioridades constante para otimizar ordenação
  static const Map<String, int> _priorityOrder = {
    'alta': 0,
    'media': 1,
    'baixa': 2
  };

  // Cache de datas parseadas para otimizar ordenação
  final Map<String, DateTime> _dateCache = {};

  // Controle da barra de pesquisa expandida
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;

  // Filtros
  String? selectedPriority; // alta, media, baixa
  String? selectedStatus; // concluida ou pendente
  DateTime? selectedDateFrom;
  DateTime? selectedDateTo;

  @override
  void initState() {
    super.initState();
    fetchTasks();

    // Configura AuthService para logout automático por token expirado
    AuthService.configure(context, widget.toggleTheme);

    // Listener para expansão da busca
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Limpa o gerenciador de tokens ao sair
    TokenManager.instance.dispose();
    AuthService.dispose();
    _searchFocusNode.dispose();
    _dateCache.clear(); // Limpa cache ao sair
    super.dispose();
  }

  // Obtém data parseada do cache para otimizar performance
  DateTime _getCachedDate(String taskId, String isoDate) {
    return _dateCache.putIfAbsent(taskId, () => DateTime.parse(isoDate));
  }

  // Faz logout e limpa tokens
  Future<void> logout() async {
    await AuthService.logout();
  }

  // Carrega tarefas da API
  Future<void> fetchTasks() async {
    setState(() => isLoading = true); // Inicia indicador
    _dateCache.clear(); // Limpa cache ao recarregar
    final fetchedTasks = await ApiService.getTasks(widget.token);
    setState(() {
      tasks = applySorting(fetchedTasks); // Ordena ao carregar
      applyFiltersAndSearch();
      isLoading = false;
    });
  }

  // Ordena as tarefas localmente conforme a opção escolhida
  List<Task> applySorting(List<Task> list) {
    final sorted = List<Task>.from(list);

    // Ordenação implícita automática (requisito 5.1.2)
    // 1º: Não concluídas primeiro, concluídas por último
    // 2º: Por prioridade (alta > media > baixa)
    // 3º: Por data mais próxima
    sorted.sort((a, b) {
      // 1. Tarefas não concluídas sempre vêm primeiro
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }

      // Se ambas têm o mesmo status de conclusão, aplica ordenação adicional
      if (sortOption == 'Data') {
        // Ordenação manual por data
        final dateA = _getCachedDate(a.id!, a.date);
        final dateB = _getCachedDate(b.id!, b.date);
        return dateA.compareTo(dateB);
      } else if (sortOption == 'Prioridade') {
        // Ordenação manual por prioridade
        final priorityComparison = (_priorityOrder[a.priority] ?? 3)
            .compareTo(_priorityOrder[b.priority] ?? 3);

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        // 3. Por data mais próxima (dentro da mesma prioridade)
        final dateA = _getCachedDate(a.id!, a.date);
        final dateB = _getCachedDate(b.id!, b.date);
        return dateA.compareTo(dateB);
      } else {
        // Ordenação IMPLÍCITA AUTOMÁTICA (Padrão)
        // 2. Por prioridade (alta > media > baixa)
        final priorityComparison = (_priorityOrder[a.priority] ?? 3)
            .compareTo(_priorityOrder[b.priority] ?? 3);

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        // 3. Por data mais próxima (dentro da mesma prioridade)
        final dateA = _getCachedDate(a.id!, a.date);
        final dateB = _getCachedDate(b.id!, b.date);
        return dateA.compareTo(dateB);
      }
    });

    return sorted;
  }

  // Atualiza a opção de ordenação e aplica novamente os filtros e busca
  void changeSorting(String? newValue) {
    if (newValue != null) {
      setState(() {
        sortOption = newValue;
        tasks = applySorting(tasks);
        applyFiltersAndSearch();
      });
    }
  }

  // Atualiza a busca e refiltra
  void updateSearch(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
      applyFiltersAndSearch();
    });
  }

  // Aplica busca e filtros locais
  void applyFiltersAndSearch() {
    filteredTasks = tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(searchQuery);
      final matchesPriority =
          selectedPriority == null || task.priority == selectedPriority;
      final matchesStatus = selectedStatus == null ||
          (selectedStatus == 'concluida' ? task.completed : !task.completed);
      // Usa cache de datas para otimizar performance
      final taskDate = _getCachedDate(task.id!, task.date);
      final matchesDateFrom = selectedDateFrom == null ||
          taskDate.isAfter(selectedDateFrom!.subtract(const Duration(days: 1)));
      final matchesDateTo = selectedDateTo == null ||
          taskDate.isBefore(selectedDateTo!.add(const Duration(days: 1)));
      return matchesSearch &&
          matchesPriority &&
          matchesStatus &&
          matchesDateFrom &&
          matchesDateTo;
    }).toList();
  }

  // Abre um seletor de data e retorna a data escolhida
  Future<void> pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      setState(() {
        selectedDateFrom = range.start;
        selectedDateTo = range.end;
        applyFiltersAndSearch();
      });
    }
  }

  // Limpa filtros aplicados
  void clearFilters() {
    setState(() {
      selectedPriority = null;
      selectedStatus = null;
      selectedDateFrom = null;
      selectedDateTo = null;
      applyFiltersAndSearch();
    });
  }

  // Verifica se a tarefa foi concluída em atraso
  bool isCompletedLate(Task task) {
    if (!task.completed) return false;

    final taskDate = _getCachedDate(task.id!, task.date);
    final now = DateTime.now();

    return taskDate.isBefore(now);
  }

  // Faz parse manual da ISO-8601 sem conversões de timezone
  DateTime _parseIsoWithoutTimezoneConversion(String isoDate) {
    // Remove timezone para evitar conversão automática
    final withoutTimezone =
        isoDate.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$|Z$'), '');
    return DateTime.parse(withoutTimezone);
  }

  // Formata data ISO para formato brasileiro
  String formatDate(String isoDate) {
    try {
      // Parse manual sem conversão de timezone
      final dateTime = _parseIsoWithoutTimezoneConversion(isoDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  // Confirma exclusão de tarefa
  Future<void> confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a tarefa "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteTask(widget.token, task.id!);
      fetchTasks();
    }
  }

  // Confirma exclusão de todas as tarefas concluídas
  Future<void> confirmDeleteCompleted() async {
    // Verifica se existem tarefas concluídas
    final completedTasks = tasks.where((task) => task.completed).toList();

    if (completedTasks.isEmpty) {
      // Mostra aviso de que não há tarefas concluídas
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nenhuma Tarefa Concluída'),
          content: const Text(
              'Não existem tarefas concluídas para serem excluídas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Deseja realmente excluir ${completedTasks.length} tarefa(s) concluída(s)?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir Todas',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteDoneTasks(widget.token);
      fetchTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchExpanded ? null : const Text('Tarefas'),
        centerTitle: true,
        actions: [
          // Container principal que controla todo o layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Barra de pesquisa expansível
                  Expanded(
                    flex: _isSearchExpanded ? 1 : 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: TextField(
                        focusNode: _searchFocusNode,
                        onChanged: updateSearch,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar tarefas...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white70),
                          suffixIcon: _isSearchExpanded
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white70),
                                  onPressed: () {
                                    _searchFocusNode.unfocus();
                                    updateSearch(''); // Limpa a busca
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Espaçamento entre pesquisa e botões
                  if (!_isSearchExpanded) const SizedBox(width: 8),

                  // Botões que aparecem/desaparecem
                  if (!_isSearchExpanded) ...[
                    // Botão de ordenação
                    ElevatedButton(
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          builder: (_) => buildSortSheet(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.sort, size: 18),
                    ),

                    const SizedBox(width: 8),

                    // Botão limpar
                    ElevatedButton(
                      onPressed: confirmDeleteCompleted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          const Text('Limpar', style: TextStyle(fontSize: 12)),
                    ),

                    const SizedBox(width: 4),

                    // Botão de tema
                    IconButton(
                      icon: const Icon(Icons.brightness_6),
                      onPressed: widget.toggleTheme,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                    ),

                    // Menu de opções
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      onSelected: (value) {
                        switch (value) {
                          case 'logout':
                            logout();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sair', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTasks,
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  final isLate = isCompletedLate(task);

                  return ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                        color: isLate ? Colors.orange.shade700 : null,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatDate(task.date)} - ${task.completed ? "Concluída" : "Pendente"}',
                            style: TextStyle(
                              color: isLate ? Colors.orange.shade600 : null,
                            ),
                          ),
                        ),
                        if (isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Text(
                              'EM ATRASO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: task.completed,
                      onChanged: (val) async {
                        final oldCompleted = task.completed;
                        task.completed = val!;

                        try {
                          // Usa método específico para atualizar apenas status
                          await ApiService.updateTaskStatus(
                              widget.token, task.id!, val);

                          // Feedback especial para conclusão em atraso
                          if (val && isCompletedLate(task)) {
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

                          fetchTasks();
                        } catch (e) {
                          // Reverte o estado em caso de erro
                          task.completed = oldCompleted;

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao atualizar status: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    onTap: () async {
                      // Visualiza detalhes da tarefa
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskDetailScreen(task: task, token: widget.token),
                        ),
                      );
                      if (result == true) {
                        fetchTasks(); // Atualiza se houve mudança
                      }
                    },
                    onLongPress: () => confirmDelete(task),
                  );
                },
              ),
            ),
      floatingActionButton: Stack(
        children: [
          // Botão de filtro (verde, em cima)
          Positioned(
            bottom: 100,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (_) => buildFilterSheet(),
                );
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              heroTag: "filter",
              child: const Icon(Icons.filter_alt, size: 18),
            ),
          ),
          // Botão de adicionar (azul, embaixo)
          Positioned(
            bottom: 20,
            right: 0,
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskFormScreen(token: widget.token),
                  ),
                );
                fetchTasks();
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              heroTag: "add",
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // Modal de filtros com dropdowns e seletor de data
  Widget buildFilterSheet() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                  child: const Text('Filtros',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              TextButton(onPressed: clearFilters, child: const Text('Limpar'))
            ],
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: selectedPriority,
            hint: const Text('Filtrar por prioridade'),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'alta', child: Text('alta')),
              DropdownMenuItem(value: 'media', child: Text('media')),
              DropdownMenuItem(value: 'baixa', child: Text('baixa')),
            ],
            onChanged: (value) {
              setState(() {
                selectedPriority = value;
                applyFiltersAndSearch();
              });
            },
          ),
          DropdownButton<String>(
            value: selectedStatus,
            hint: const Text('Filtrar por status'),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'pendente', child: Text('pendente')),
              DropdownMenuItem(value: 'concluida', child: Text('concluida')),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatus = value;
                applyFiltersAndSearch();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Período'),
                  onPressed: pickDateRange,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // Modal de ordenação
  Widget buildSortSheet() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                  child: const Text('Ordenar por',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          ...['Inteligente', 'Data', 'Prioridade'].map((option) {
            String description = '';
            if (option == 'Inteligente') {
              description = 'Por prioridade e data (recomendado)';
            } else if (option == 'Data') {
              description = 'Apenas por data de vencimento';
            } else if (option == 'Prioridade') {
              description = 'Apenas por nível de prioridade';
            }

            return ListTile(
              title: Text(option),
              subtitle: Text(description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              leading: Radio<String>(
                value: option == 'Inteligente' ? 'Padrão' : option,
                groupValue: sortOption,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      sortOption = value;
                      tasks = applySorting(tasks);
                      applyFiltersAndSearch();
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
