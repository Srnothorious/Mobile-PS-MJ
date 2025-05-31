# Mobile Mega Todo List

Aplicativo mobile do sistema de gerenciamento de tarefas da MegaJr.

## 📱 Tecnologias
- Flutter 3.x
- Dart
- Integração com backend Node.js (JWT)
- Provider
- Local Notifications
- Persistência de sessão
- Tema escuro
- Integração com calendário

## 🚀 Funcionalidades
- Autenticação (login e registro)
- Listar tarefas
- Criar, editar e excluir tarefas
- Filtro por prioridade e status
- Busca por título
- Visualização detalhada da tarefa
- Notificações locais para tarefas agendadas
- Persistência de login com JWT
- Modo escuro automático
- Feedbacks de carregamento e estado

## ⚙️ Configuração

### 1. Clone os projetos

```bash
# Backend
git clone https://github.com/gabrielsantr/back-end-mega-todo-list.git
cd back-end-mega-todo-list
npm install

# Mobile
git clone https://github.com/Srnothorious/Mobile-PS-MJ.git
cd Mobile-PS-MJ
flutter pub get
```

### 2. Configure o backend

Crie um arquivo `.env` no diretório do backend com os seguintes valores:

```env
DATABASE_URL="postgresql://usuario:senha@localhost:5432/todolist"
JWT_SECRET="sua_chave_secreta"
PORT=3000
```

Depois rode os comandos:

```bash
npx prisma generate
npx prisma migrate deploy
```

### 3. Inicie o backend

```bash
npm run dev
```

### 4. Configure o app mobile

No arquivo onde está a constante `baseUrl`, ajuste conforme seu ambiente:

#### Emulador Android (localhost):
```dart
const String baseUrl = 'http://10.0.2.2:3000/';
```

#### Dispositivo físico (na mesma rede):
```dart
const String baseUrl = 'http://192.168.X.X:3000/';
```

#### Produção:
```dart
const String baseUrl = 'https://seu-backend.com/';
```

### 5. Execute o app

```bash
flutter run
```

---

Desenvolvido para o desafio Mega ToDo List 📝
