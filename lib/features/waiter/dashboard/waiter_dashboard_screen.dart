import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/models/table.dart';
import '../../../core/repositories/menu_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/table_repository.dart';
import '../../../core/utils/currency.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/menu_card.dart';
import '../../../widgets/order_tile.dart';
import '../../../widgets/table_card.dart';

class WaiterDashboardScreen extends StatefulWidget {
  const WaiterDashboardScreen({super.key});

  @override
  State<WaiterDashboardScreen> createState() => _WaiterDashboardScreenState();
}

class _WaiterDashboardScreenState extends State<WaiterDashboardScreen> {
  final _menuRepository = MenuRepository(ApiClient.instance);
  final _tableRepository = TableRepository(ApiClient.instance);
  final _orderRepository = OrderRepository(ApiClient.instance);
  final _instructionsController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String _selectedCategory = 'all';
  int? _selectedTableId;
  List<RestaurantTable> _tables = const [];
  List<MenuItem> _menu = const [];
  final Map<int, int> _cart = {};

  static const List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'All', 'icon': '🍽️'},
    {'key': 'beer', 'label': 'Beer', 'icon': '🍺'},
    {'key': 'malt', 'label': 'Malt', 'icon': '🍷'},
    {'key': 'soft-drinks', 'label': 'Soft Drinks', 'icon': '🥤'},
    {'key': 'water', 'label': 'Water', 'icon': '💧'},
    {'key': 'energy-drinks', 'label': 'Energy', 'icon': '⚡'},
    {'key': 'juice', 'label': 'Juice', 'icon': '🧃'},
    {'key': 'spirits', 'label': 'Spirits', 'icon': '🥃'},
    {'key': 'ready-to-drink', 'label': 'RTD', 'icon': '🍹'},
    {'key': 'rice', 'label': 'Rice', 'icon': '🍚'},
    {'key': 'pepper-soup', 'label': 'Pepper Soup', 'icon': '🍜'},
    {'key': 'grills', 'label': 'Grills', 'icon': '🍖'},
    {'key': 'soups', 'label': 'Soups', 'icon': '🥘'},
    {'key': 'swallow', 'label': 'Swallow', 'icon': '🫓'},
    {'key': 'extras', 'label': 'Extras', 'icon': '🥗'},
    {'key': 'cigarettes', 'label': 'Cigarettes', 'icon': '🚬'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final tablesResult = await _tableRepository.fetchTables();
    final menuResult = await _menuRepository.fetchMenu();

    if (!mounted) return;

    if (tablesResult.success && tablesResult.data != null) {
      _tables = tablesResult.data!;
      if (_selectedTableId == null && _tables.isNotEmpty) {
        _selectedTableId = _tables.first.id;
      }
    }

    if (menuResult.success && menuResult.data != null) {
      _menu = menuResult.data!;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await ApiClient.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  List<MenuItem> get _filteredMenu {
    final search = _searchController.text.trim().toLowerCase();
    return _menu.where((item) {
      final matchesCategory =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final matchesSearch = search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  double get _grandTotal {
    return _cart.entries.fold<double>(0, (sum, entry) {
      final item = _menu.firstWhere(
        (menuItem) => menuItem.id == entry.key,
        orElse: () => const MenuItem(
          id: 0, name: '', description: '', price: 0, category: '',
        ),
      );
      return sum + (item.price * entry.value);
    });
  }

  int get _cartItemsCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  void _toggleQuantity(int itemId, {required bool increment}) {
    setState(() {
      final current = _cart[itemId] ?? 0;
      if (increment) {
        _cart[itemId] = current + 1;
      } else if (current > 1) {
        _cart[itemId] = current - 1;
      } else {
        _cart.remove(itemId);
      }
    });
  }

  Future<void> _confirmOrder() async {
    if (_selectedTableId == null || _cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a table and add at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cartItems = _cart.entries
        .map((entry) => {'menu_item_id': entry.key, 'quantity': entry.value})
        .toList();

    final tableName = _tables
        .firstWhere(
          (t) => t.id == _selectedTableId,
          orElse: () => const RestaurantTable(id: 0, name: 'Unknown', status: ''),
        )
        .name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Confirm Order'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_restaurant, size: 18),
                    const SizedBox(width: 8),
                    Text(tableName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ..._cart.entries.map((entry) {
                final item = _menu.firstWhere(
                  (menuItem) => menuItem.id == entry.key,
                  orElse: () => const MenuItem(
                    id: 0, name: '', description: '', price: 0, category: '',
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.name} × ${entry.value}'),
                      Text(CurrencyFormatter.format(item.price * entry.value)),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              if (_instructionsController.text.isNotEmpty) ...[
                Text('Instructions:', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_instructionsController.text),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(
                    CurrencyFormatter.format(_grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _orderRepository.submitOrder(
      tableId: _selectedTableId!,
      items: cartItems,
      instructions: _instructionsController.text,
    );

    if (!mounted) return;

    if (result.success) {
      _cart.clear();
      _instructionsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to submit order'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 980;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiter POS'),
        actions: [
          if (_cartItemsCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                label: Text('$_cartItemsCount'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _showCartBottomSheet,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: isWide
                      ? _buildWideLayout(theme)
                      : _buildNarrowLayout(theme),
                );
              },
            ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Order Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions',
                      hintText: 'E.g., No onions, Extra spicy...',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _cart.isEmpty
                        ? const EmptyState(
                            title: 'Empty Cart',
                            message: 'Tap menu items to add them here.',
                          )
                        : ListView.builder(
