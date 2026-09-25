import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/role_based_drawer.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final _apiClient = ApiClient.instance;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  List<dynamic> _pendingCancellations = const [];
  bool _loadingCancellations = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPendingCancellations();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadStats();
      _loadPendingCancellations();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      Endpoints.v1Reports,
      queryParameters: {'scope': 'day', 'top_items': 10},
      onData: (data) => data,
    );
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() {
        _stats = result.data;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _apiClient.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _loadPendingCancellations() async {
    setState(() => _loadingCancellations = true);
    final result = await _apiClient.get<Map<String, dynamic>>(
      Endpoints.v1Operations,
      queryParameters: {'resource': 'cancellations'},
    );
    if (!mounted) return;
    setState(() {
      if (result.success && result.data != null) {
        _pendingCancellations =
            result.data!['requests'] as List<dynamic>? ?? const [];
      } else {
        _pendingCancellations = const [];
      }
      _loadingCancellations = false;
    });
  }

  Future<void> _reviewCancellation(int requestId, String decision) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      Endpoints.v1Operations,
      body: {
        'action': 'cancel.review',
        'request_id': requestId,
        'decision': decision,
      },
    );
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancellation request $decision'),
          backgroundColor: decision == 'approved'
              ? Colors.green
              : Colors.orange,
        ),
      );
      _loadPendingCancellations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to review cancellation'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: const RoleBasedDrawer(role: 'manager', currentRoute: '/manager'),
      body: _loading
          ? const LoadingIndicator()
          : _stats == null
          ? const Center(child: Text('Unable to load data'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final summaryDay = (_stats!['summary_day'] as num?)?.toDouble() ?? 0;
    final summaryWeek = (_stats!['summary_week'] as num?)?.toDouble() ?? 0;
    final summaryMonth = (_stats!['summary_month'] as num?)?.toDouble() ?? 0;
    final completedOrders = (_stats!['completed_orders'] as num?)?.toInt() ?? 0;
    final pendingOrders = (_stats!['pending_orders'] as num?)?.toInt() ?? 0;
    final kitchenOrders =
        (_stats!['total_kitchen_orders'] as num?)?.toInt() ?? 0;
    final barOrders = (_stats!['total_bar_orders'] as num?)?.toInt() ?? 0;
    final tables = (_stats!['tables'] as List<dynamic>? ?? []);
    final topItems = (_stats!['top_items'] as List<dynamic>? ?? []);
    final sales = (_stats!['sales'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Summary',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                label: 'Today',
                value: CurrencyFormatter.format(summaryDay),
                color: AppColors.accent,
              ),
              _StatCard(
                label: 'This Week',
                value: CurrencyFormatter.format(summaryWeek),
                color: AppColors.primary,
              ),
              _StatCard(
                label: 'This Month',
                value: CurrencyFormatter.format(summaryMonth),
                color: const Color(0xFFE76F51),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Order Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _StatCard(
                label: 'Completed',
                value: '$completedOrders',
                color: Colors.green,
              ),
              _StatCard(
                label: 'Pending',
                value: '$pendingOrders',
                color: Colors.orange,
              ),
              _StatCard(
                label: 'Kitchen',
                value: '$kitchenOrders',
                color: Colors.blue,
              ),
              _StatCard(
                label: 'Bar',
                value: '$barOrders',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Table Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index] as Map<String, dynamic>;
                final name =
                    table['name']?.toString() ?? 'Table ${table['id']}';
                final status = (table['status']?.toString() ?? 'available')
                    .toLowerCase();
                final color = switch (status) {
                  'occupied' => Colors.red,
                  'reserved' => Colors.blue,
                  'closed' => Colors.grey,
                  _ => Colors.green,
                };
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          if (_pendingCancellations.isNotEmpty) ...[
            Text(
              'Pending Cancellation Requests',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.orange.shade50,
              child: Column(
                children: _pendingCancellations.map((request) {
                  final req = request as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    title: Text(
                      'Order #${req['order_id']} - Table ${req['table_id']}',
                    ),
                    subtitle: Text('Reason: ${req['reason'] ?? 'No reason'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          tooltip: 'Approve',
                          onPressed: () => _reviewCancellation(
                            (req['id'] as num).toInt(),
                            'approved',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () => _reviewCancellation(
                            (req['id'] as num).toInt(),
                            'rejected',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else if (!_loadingCancellations) ...[
            const SizedBox(height: 8),
            Text(
              'No pending cancellation requests',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          if (topItems.isNotEmpty) ...[
            Text(
              'Top Selling Items',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: topItems.take(5).toList().asMap().entries.map((
                  entry,
                ) {
                  final item = entry.value as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text(item['item_name']?.toString() ?? 'Item'),
                    trailing: Text('Qty: ${item['quantity_sold']}'),
                  );
                }).toList(),
              ),
            ),
          ],
          if (sales.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Recent Orders',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: sales.take(10).toList().map((order) {
                  final orderMap = order as Map<String, dynamic>;
                  return ListTile(
                    title: Text('Order #${orderMap['order_id']}'),
                    subtitle: Text('Table ${orderMap['table_id']}'),
                    trailing: Text(
                      CurrencyFormatter.format(
                        (orderMap['revenue'] as num?)?.toDouble() ?? 0,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
