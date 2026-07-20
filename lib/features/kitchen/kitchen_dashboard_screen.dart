import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/models/order_item.dart';
import '../../widgets/loading_indicator.dart';

class KitchenDashboardScreen extends StatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  final _apiClient = ApiClient.instance;
  late final Timer _timer;
  List<OrderItemModel> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final result = await _apiClient.get(Endpoints.status);
    if (!mounted) {
      return;
    }

    if (result.success && result.data != null) {
      final rawItems = result.data!['order_items'] as List<dynamic>? ?? const <dynamic>[];
      final orderItems = rawItems
          .map((entry) => OrderItemModel.fromJson(Map<String, dynamic>.from(entry as Map)))
          .where((item) => item.routedTo == 'kitchen')
          .toList();

      setState(() {
        _loading = false;
        _items = orderItems;
      });
    }
  }

  Future<void> _updateStatus(int itemId, String status) async {
    final result = await _apiClient.post(
      Endpoints.status,
      body: {'item_id': itemId, 'status': status},
    );
    if (!mounted) {
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item updated to $status'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to update'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
    await _loadOrders();
  }

  Future<void> _logout() async {
    await _apiClient.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'pending' => Colors.orange,
      'preparing' => Colors.blue,
      'ready' => Colors.green,
      'served' => Colors.purple,
      'completed' => Colors.grey,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((i) => i.status == 'pending').toList();
    final preparing = _items.where((i) => i.status == 'preparing').toList();
    final ready = _items.where((i) => i.status == 'ready').toList();
    final served = _items.where((i) => i.status == 'served').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Queue'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('${_items.length} items', style: const TextStyle(fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('All orders completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('Waiting for new orders...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: 'Pending (${pending.length})'),
                          Tab(text: 'Preparing (${preparing.length})'),
                          Tab(text: 'Ready (${ready.length})'),
                          Tab(text: 'Served (${served.length})'),
                        ],
                        isScrollable: true,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildOrderList(pending),
                            _buildOrderList(preparing),
                            _buildOrderList(ready),
                            _buildOrderList(served),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderList(List<OrderItemModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final statusColor = _statusColor(item.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('Table ${item.orderId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.itemName ?? 'Item #${item.id}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Qty: ${item.quantity} • Unit: ₦${item.unitPrice.toStringAsFixed(2)}'),
                if (item.status == 'pending') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _updateStatus(item.id, 'preparing'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Start Preparing', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.status == 'preparing') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _updateStatus(item.id, 'ready'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Mark Ready', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.status == 'ready') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _updateStatus(item.id, 'served'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Mark Served', style: TextStyle(color: Colors.purple)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.status == 'served') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _updateStatus(item.id, 'completed'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Complete', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
