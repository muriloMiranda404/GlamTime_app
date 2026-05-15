import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/service_model.dart';
import '../../utils/app_theme.dart';

class ManageServices extends StatefulWidget {
  const ManageServices({super.key});

  @override
  State<ManageServices> createState() => _ManageServicesState();
}

class _ManageServicesState extends State<ManageServices> {
  final _dbService = DatabaseService();
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  final List<String> _categories = [
    'Unhas',
    'Cabelo',
    'Sobrancelha',
    'Estética',
    'Outros',
  ];

  void _showServiceDialog([ServiceModel? service]) {
    final nameController = TextEditingController(text: service?.name);
    final descController = TextEditingController(text: service?.description);
    final priceController = TextEditingController(
      text: service?.price.toString(),
    );
    final durationController = TextEditingController(
      text: service?.durationInMinutes.toString(),
    );
    String selectedCategory = service?.category ?? 'Outros';
    bool isActive = service?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            service == null ? 'Novo Serviço' : 'Editar Serviço',
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Nome', Icons.label_outline),
                _buildTextField(
                  descController,
                  'Descrição',
                  Icons.description_outlined,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        priceController,
                        'Preço',
                        Icons.attach_money,
                        TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        durationController,
                        'Duração (min)',
                        Icons.timer_outlined,
                        TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                      color: AppTheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Serviço Ativo',
                    style: TextStyle(color: AppTheme.textDark),
                  ),
                  value: isActive,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: AppTheme.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, insira o nome do serviço'),
                    ),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, insira um preço válido'),
                    ),
                  );
                  return;
                }

                final newService = ServiceModel(
                  id:
                      service?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price: price,
                  durationInMinutes:
                      int.tryParse(durationController.text) ?? 30,
                  category: selectedCategory,
                  isActive: isActive,
                );

                if (service == null) {
                  await _dbService.addService(newService);
                } else {
                  await _dbService.updateService(newService);
                }

                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                service == null ? 'ADICIONAR' : 'SALVAR',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType type = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Gerenciar Serviços',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: _dbService.services,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                var services = snapshot.data!;

                // Filter by category
                if (_selectedFilter != 'Todos') {
                  services = services
                      .where((s) => s.category == _selectedFilter)
                      .toList();
                }

                // Search by name
                if (_searchQuery.isNotEmpty) {
                  services = services
                      .where(
                        (s) => s.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum serviço encontrado.',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final s = services[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: _buildServiceListItem(s),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Serviço',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Buscar serviços...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final filters = ['Todos', ..._categories];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary.withOpacity(0.2),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceListItem(ServiceModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(s.isActive ? 1.0 : 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(s.category),
            color: AppTheme.textDark.withOpacity(s.isActive ? 1.0 : 0.5),
          ),
        ),
        title: Text(
          s.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark.withOpacity(s.isActive ? 1.0 : 0.5),
            decoration: s.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.category} • R\$ ${s.price.toStringAsFixed(2)} • ${s.durationInMinutes}min',
              style: TextStyle(
                color: AppTheme.textLight.withOpacity(s.isActive ? 1.0 : 0.5),
              ),
            ),
            if (!s.isActive)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'INATIVO',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                s.isActive ? Icons.visibility : Icons.visibility_off,
                color: s.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                final updatedService = ServiceModel(
                  id: s.id,
                  name: s.name,
                  description: s.description,
                  price: s.price,
                  durationInMinutes: s.durationInMinutes,
                  category: s.category,
                  isActive: !s.isActive,
                );
                _dbService.updateService(updatedService);
              },
              tooltip: s.isActive ? 'Desativar' : 'Ativar',
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => _showServiceDialog(s),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(s),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Unhas':
        return Icons.brush_outlined;
      case 'Cabelo':
        return Icons.content_cut_outlined;
      case 'Sobrancelha':
        return Icons.remove_red_eye_outlined;
      case 'Estética':
        return Icons.face_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  void _confirmDelete(ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Serviço?'),
        content: Text(
          'Tem certeza que deseja excluir o serviço "${service.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteService(service.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
