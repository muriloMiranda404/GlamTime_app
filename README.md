# 💅 GlamTime

Aplicativo de agendamento para salões de beleza, desenvolvido em Flutter com Firebase.

## Funcionalidades

**Clientes**
- Cadastro e login
- Catálogo de serviços com filtro por categoria e busca
- Seleção de múltiplos serviços em um único agendamento
- Escolha de data, horário e forma de pagamento
- Visualização e cancelamento de agendamentos
- Notificações locais de lembrete (24h e 1h antes)

**Administrador**
- Agenda com filtro por profissional
- Gerenciamento de serviços (criar, editar, ativar/desativar, excluir)
- Gerenciamento de profissionais
- Dashboard financeiro com gráficos de receita e despesas
- Relatórios por período e por profissional
- Bloqueio de horários
- Notificação via WhatsApp (manual ou via gateway automatizado)

## Stack

- **Flutter** (Dart)
- **Firebase** (Firestore, Auth local via SharedPreferences)
- **Pacotes principais:** `provider`, `fl_chart`, `flutter_local_notifications`, `url_launcher`, `google_fonts`

## Como rodar

```bash
flutter pub get
flutter run
```

> Requer um projeto Firebase configurado. Substitua o `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) pelos seus próprios.

## Estrutura
lib/
├── main.dart
├── models/          # AppointmentModel, ServiceModel, etc.
├── providers/       # AuthProvider
├── screens/         # Telas do app (home, booking, admin...)
├── services/        # DatabaseService, AuthService, NotificationService
├── utils/           # AppTheme
└── widgets/         # ServiceCard, CategoryFilter

## Status

Concluído e funcional.

## Aviso

As chaves de API e arquivos de configuração do Firebase presentes no repositório são de um projeto de desenvolvimento. **Não use em produção sem substituí-las.**
