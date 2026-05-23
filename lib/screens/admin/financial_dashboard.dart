import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/database_service.dart';
import '../../models/expense_model.dart';
import '../../models/appointment_model.dart';
import '../../models/professional_model.dart';
import '../../utils/app_theme.dart';

class FinancialDashboard extends StatefulWidget {
  const FinancialDashboard({super.key});

  @override
  State<FinancialDashboard> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard> {
  final _dbService = DatabaseService();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String _selectedPeriod = 'Este Mês';

  late final Stream<List<ProfessionalModel>> _professionalsStream;
  late final Stream<List<AppointmentModel>> _appointmentsStream;
  late final Stream<List<ExpenseModel>> _expensesStream;

  @override
  void initState() {
    super.initState();
    _professionalsStream = _dbService.professionals;
    _appointmentsStream = _dbService.allAppointments;
    _expensesStream = _dbService.expenses;
  }

  bool _isDateInPeriod(DateTime date, String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    switch (period) {
      case 'Hoje':
        return date.isAfter(today.subtract(const Duration(seconds: 1)));
      case 'Esta Semana':
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      case 'Este Mês':
        return date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Gestão Financeira',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<List<ProfessionalModel>>(
        stream: _professionalsStream,
        builder: (context, profSnapshot) {
          return StreamBuilder<List<AppointmentModel>>(
            stream: _appointmentsStream,
            builder: (context, apptSnapshot) {
              return StreamBuilder<List<ExpenseModel>>(
                stream: _expensesStream,
                builder: (context, expenseSnapshot) {
                  if (apptSnapshot.connectionState == ConnectionState.waiting ||
                      expenseSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      profSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final allAppointments = apptSnapshot.data ?? [];
                  final allExpenses = expenseSnapshot.data ?? [];
                  final professionals = profSnapshot.data ?? [];

                  final appointments = allAppointments.where((a) {
                    return _isDateInPeriod(a.dateTime, _selectedPeriod);
                  }).toList();

                  final expenses = allExpenses
                      .where((e) => _isDateInPeriod(e.date, _selectedPeriod))
                      .toList();

                  double receivedRevenue = appointments
                      .where((a) => a.status != 'cancelled' && a.isPaid)
                      .fold(0, (sum, item) => sum + item.totalPrice);

                  double pendingRevenue = appointments
                      .where((a) => a.status != 'cancelled' && !a.isPaid)
                      .fold(0, (sum, item) => sum + item.totalPrice);

                  double totalExpenses = expenses.fold(
                    0,
                    (sum, item) => sum + item.amount,
                  );
                  double totalRevenue = receivedRevenue + pendingRevenue;
                  double netProfit = receivedRevenue - totalExpenses;

                  Map<String, int> serviceCount = {};
                  for (var appt in appointments) {
                    if (appt.status != 'cancelled') {
                      serviceCount[appt.serviceName] =
                          (serviceCount[appt.serviceName] ?? 0) + 1;
                    }
                  }
                  String mostPopularService = serviceCount.entries.isEmpty
                      ? 'Nenhum'
                      : serviceCount.entries
                            .reduce((a, b) => a.value > b.value ? a : b)
                            .key;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(),
                        const SizedBox(height: 24),
                        _buildSummaryCards(
                          receivedRevenue,
                          pendingRevenue,
                          totalExpenses,
                          netProfit,
                        ),
                        const SizedBox(height: 24),
                        _buildPopularServiceCard(mostPopularService),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Desempenho Semanal'),
                            TextButton.icon(
                              onPressed: () => _showReportDialog(
                                totalRevenue,
                                totalExpenses,
                                netProfit,
                                mostPopularService,
                                appointments.length,
                                professionals.isNotEmpty
                                    ? professionals.first.name
                                    : 'Geral',
                              ),
                              icon: const Icon(
                                Icons.description_outlined,
                                size: 18,
                              ),
                              label: const Text('Relatório'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        _buildRevenueChart(appointments),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Distribuição de Despesas'),
                        _buildExpenseChart(expenses),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Controle de Despesas'),
                        _buildExpenseList(expenses),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showAddExpenseDialog,
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
      label: const Text(
        'Nova Despesa',
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}

  Widget _buildPeriodSelector() {
    final periods = ['Hoje', 'Esta Semana', 'Este Mês', 'Tudo'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedPeriod = period);
              },
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReportDialog(
    double revenue,
    double expenses,
    double profit,
    String popular,
    int totalAppts,
    String professionalName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Resumo $_selectedPeriod - $professionalName',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportItem(
              'Faturamento Total',
              _currencyFormat.format(revenue),
            ),
            _buildReportItem(
              'Despesas Totais',
              _currencyFormat.format(expenses),
            ),
            _buildReportItem(
              'Lucro Líquido',
              _currencyFormat.format(profit),
              isBold: true,
              color: profit >= 0 ? Colors.green : Colors.red,
            ),
            const Divider(height: 24),
            _buildReportItem('Serviço Popular', popular),
            _buildReportItem('Total de Agendamentos', totalAppts.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppTheme.textDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    double received,
    double pending,
    double expenses,
    double profit,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary,
                AppTheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo Real',
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profit >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profit >= 0 ? 'Lucro' : 'Prejuízo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(profit),
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      'Ganhos',
                      _currencyFormat.format(received),
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMiniStat(
                      'Despesas',
                      _currencyFormat.format(expenses),
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendente',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(pending),
                    style: GoogleFonts.montserrat(
                      color: AppTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textLight, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.6), size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularServiceCard(String serviceName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppTheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Serviço Mais Agendado',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                ),
                Text(
                  serviceName,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<AppointmentModel> appointments) {
    Map<int, double> dailyRevenue = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    for (var appt in appointments) {
      if (appt.status != 'cancelled' && appt.dateTime.isAfter(startOfWeek)) {
        int weekday = appt.dateTime.weekday - 1;
        dailyRevenue[weekday] = (dailyRevenue[weekday] ?? 0) + appt.totalPrice;
      }
    }

    double maxRev = dailyRevenue.values.fold(
      100.0,
      (max, v) => v > max ? v : max,
    );

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxRev * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppTheme.primary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'R\$ ${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Seg',
                    'Ter',
                    'Qua',
                    'Qui',
                    'Sex',
                    'Sáb',
                    'Dom',
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt() % 7],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyRevenue[i]!,
                  color: AppTheme.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildExpenseChart(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text(
          'Nenhuma despesa para exibir',
          style: TextStyle(color: AppTheme.textLight),
        ),
      );
    }

    Map<String, double> categoryTotals = {};
    for (var exp in expenses) {
      categoryTotals[exp.category] =
          (categoryTotals[exp.category] ?? 0) + exp.amount;
    }

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.grey,
    ];

    int colorIndex = 0;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 50,
          sections: categoryTotals.entries.map((entry) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;
            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: '${entry.key}\n${_currencyFormat.format(entry.value)}',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return const SizedBox();

    return Column(
      children: expenses
          .map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accent,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.textDark,
                  size: 20,
                ),
              ),
              title: Text(
                e.description,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(e.date),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                _currencyFormat.format(e.amount),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _showAddExpenseDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Produtos';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Nova Despesa',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Produtos', 'Aluguel', 'Energia', 'Materiais', 'Outros']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final expense = ExpenseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: descController.text,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    date: DateTime.now(),
                    category: selectedCategory,
                  );
                  await _dbService.addExpense(expense);
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text(
                'ADICIONAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
