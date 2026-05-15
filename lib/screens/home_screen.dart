import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/service_model.dart';
import 'booking_screen.dart';
import '../widgets/service_card.dart';
import '../widgets/category_filter.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final List<ServiceModel> _selectedServices = [];
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primary),
              accountName: Text(auth.userModel?.name ?? 'Cliente'),
              accountEmail: Text(auth.userModel?.phone ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppTheme.primary, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.textDark),
              title: const Text('Meus Agendamentos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/my_appointments');
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textDark,
                      ),
                      SizedBox(width: 16),
                      Text('Notificações Push'),
                    ],
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                auth.signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Olá, ${auth.userModel?.name.split(' ')[0] ?? "Cliente"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.textLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Opacity(
                  opacity: 0.2,
                  child: Icon(Icons.spa, size: 150, color: Colors.white),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () =>
                    Navigator.pushNamed(context, '/my_appointments'),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => auth.signOut(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolha seus serviços',
                    style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar serviço...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) =>
                        setState(() => _selectedCategory = category),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<ServiceModel>>(
            stream: _db.services,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final services = snapshot.data!
                  .where((s) => s.isActive)
                  .where(
                    (s) =>
                        _selectedCategory == 'Todos' ||
                        s.category == _selectedCategory,
                  )
                  .where(
                    (s) => s.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

              if (services.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Nenhum serviço encontrado.')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final service = services[index];
                    final isSelected = _selectedServices.any(
                      (s) => s.id == service.id,
                    );

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: ServiceCard(
                              service: service,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedServices.removeWhere(
                                      (s) => s.id == service.id,
                                    );
                                  } else {
                                    _selectedServices.add(service);
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }, childCount: services.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: _selectedServices.isNotEmpty ? _buildSummarySheet() : null,
    );
  }

  Widget _buildSummarySheet() {
    final totalValue = _selectedServices.fold<double>(
      0,
      (sum, s) => sum + s.price,
    );
    final totalTime = _selectedServices.fold<int>(
      0,
      (sum, s) => sum + s.durationInMinutes,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedServices.length} serviços selecionados',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$totalTime min • R\$ ${totalValue.toStringAsFixed(2)}'),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingScreen(services: _selectedServices),
                    ),
                  );
                },
                child: const Text('Agendar Agora'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
