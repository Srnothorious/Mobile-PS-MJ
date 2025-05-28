// Modelo de dados para Task
class Task {
  final String? id; // Identificador gerado pelo backend
  final String title; // Título da tarefa
  final String description; // Descrição detalhada
  final String date; // Data formatada
  final String priority; // Prioridade (ex: alta, média, baixa)
  bool completed; // Status de conclusão

  // Construtor da classe
  Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    this.completed = false, // Padrão: não concluída
  });

  // Constrói Task a partir de JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'], // Lê ID
      title: json['title'], // Lê título
      description: json['description'], // Lê descrição
      date: json['date'], // Lê data
      priority: json['priority'], // Lê prioridade
      completed: json['completed'] ?? false, // Lê status ou false
    );
  }

  // Converte Task em JSON para envio
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'priority': priority,
      'completed': completed,
    };
  }
}
