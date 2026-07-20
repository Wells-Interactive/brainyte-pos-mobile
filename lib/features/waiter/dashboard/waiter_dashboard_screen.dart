import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/models/table.dart';
import '../../../core/repositories/menu_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/table_repository.dart';
import '../../../core/utils/currency.dart';
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

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel: Tables, Categories, Search, Menu Grid
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table Selection
              _buildTableSelector(),
              const SizedBox(height: 12),
              // Category Chips
              _buildCategoryChips(),
              const SizedBox(height: 12),
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search menu items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // Menu Grid
              Expanded(
                child: _filteredMenu.isEmpty
                    ? const EmptyState(
                        title: 'No Menu Items',
                        message: 'No items match your search or category filter.',
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredMenu.length,
                        itemBuilder: (context, index) {
                          final item = _filteredMenu[index];
                          final qty = _cart[item.id] ?? 0;
                          return MenuCard(
                            item: item,
                            quantity: qty,
                            onAdd: () => _toggleQuantity(item.id, increment: true),
                            onRemove: () => _toggleQuantity(item.id, increment: false),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right Panel: Cart Sidebar
        SizedBox(
          width: 340,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Selector
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTableId,
                    decoration: InputDecoration(
                      labelText: 'Select Table',
                      prefixIcon: const Icon(Icons.table_restaurant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: _tables.map((table) {
                      return DropdownMenuItem<int>(
                        value: table.id,
                        child: Text('${table.name} (${table.status})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedTableId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Order Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  // Special Instructions
                  TextField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      hintText: 'Special instructions...',
                      prefixIcon: const Icon(Icons.notes, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Cart Items List
                  Expanded(
                    child: _cart.isEmpty
                        ? const EmptyState(
                            title: 'Cart Empty',
                            message: 'Tap items from the menu to add them here.',
                          )
                        : ListView.builder(
                            itemCount: _cart.entries.length,
                            itemBuilder: (context, index) {
                              final entry = _cart.entries.elementAt(index);
                              final item = _menu.firstWhere(
                                (menuItem) => menuItem.id == entry.key,
                                orElse: () => const MenuItem(
                                  id: 0, name: '', description: '', price: 0, category: '',
                                ),
                              );
                              return OrderTile(
                                item: item,
                                quantity: entry.value,
                                onIncrement: () => _toggleQuantity(item.id, increment: true),
                                onDecrement: () => _toggleQuantity(item.id, increment: false),
                                onRemove: () => setState(() => _cart.remove(item.id)),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 20),
                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(
                        CurrencyFormatter.format(_grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Confirm Order Button
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: (_selectedTableId != null && _cart.isNotEmpty) ? _confirmOrder : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm Order', style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Selection - Horizontal Scroll
          _buildTableSelector(),
          const SizedBox(height: 12),
          // Category Chips
          _buildCategoryChips(),
          const SizedBox(height: 12),
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Menu Grid
          ..._filteredMenu.isEmpty
              ? [
                  const EmptyState(
                    title: 'No Menu Items',
                    message: 'No items match your search or category filter.',
                  ),
                ]
              : [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _filteredMenu.length,
                    itemBuilder: (context, index) {
                      final item = _filteredMenu[index];
                      final qty = _cart[item.id] ?? 0;
                      return MenuCard(
                        item: item,
                        quantity: qty,
                        onAdd: () => _toggleQuantity(item.id, increment: true),
                        onRemove: () => _toggleQuantity(item.id, increment: false),
                      );
                    },
                  ),
                ],
          const SizedBox(height: 20),
          // Quick Order Summary Strip
          if (_cart.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cart ($_cartItemsCount items)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(
                          CurrencyFormatter.format(_grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: _showCartBottomSheet,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('View Cart & Confirm'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    return SizedBox(
      height: 100,
      child: _tables.isEmpty
          ? const Center(child: Text('No tables available', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tables.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final table = _tables[index];
                return SizedBox(
                  width: 110,
                  child: TableCard(
                    table: table,
                    isSelected: table.id == _selectedTableId,
                    onTap: () => setState(() => _selectedTableId = table.id),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['key'];
          return FilterChip(
            label: Text('${category['icon']} ${category['label']}'),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = category['key']!),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
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
                  // Table Selector in Bottom Sheet
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTableId,
                    decoration: InputDecoration(
                      labelText: 'Select Table',
                      prefixIcon: const Icon(Icons.table_restaurant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: _tables.map((table) {
                      return DropdownMenuItem<int>(
                        value: table.id,
                        child: Text('${table.name} (${table.status})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedTableId = value);
                    },
                  ),
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
                            controller: scrollController,
                            itemCount: _cart.entries.length,
                            itemBuilder: (context, index) {
                              final entry = _cart.entries.elementAt(index);
                              final item = _menu.firstWhere(
                                (menuItem) => menuItem.id == entry.key,
                                orElse: () => const MenuItem(
                                  id: 0, name: '', description: '', price: 0, category: '',
                                ),
                              );
                              return OrderTile(
                                item: item,
                                quantity: entry.value,
                                onIncrement: () => _toggleQuantity(item.id, increment: true),
                                onDecrement: () => _toggleQuantity(item.id, increment: false),
                                onRemove: () => setState(() => _cart.remove(item.id)),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 20),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: (_selectedTableId != null && _cart.isNotEmpty) ? () {
                        Navigator.pop(context);
                        _confirmOrder();
                      } : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm Order', style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
