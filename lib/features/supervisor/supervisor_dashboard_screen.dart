import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency.dart';
import '../../widgets/loading_indicator.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final _apiClient = ApiClient.instance;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadStats());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final result = await _apiClient.get('/API/Status/index.php?stats=1');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _stats == null
              ? const Center(child: Text('Unable to load data'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final summaryDay = (_stats!['summary_day'] as num?)?.toDouble() ?? 0;
    final completedOrders = (_stats!['completed_orders'] as num?)?.toInt() ?? 0;
    final pendingOrders = (_stats!['pending_orders'] as num?)?.toInt() ?? 0;
    final kitchenOrders = (_stats!['total_kitchen_orders'] as num?)?.toInt() ?? 0;
    final barOrders = (_stats!['total_bar_orders'] as num?)?.toInt() ?? 0;
    final tables = (_stats!['tables'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Revenue",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(summaryDay),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedOrders completed orders',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order Status Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatusCard(
                label: 'Pending Orders',
                value: '$pendingOrders',
                icon: Icons.hourglass_empty,
                color: Colors.orange,
              ),
              _StatusCard(
                label: 'Kitchen Queue',
                value: '$kitchenOrders',
                icon: Icons.kitchen,
                color: Colors.blue,
              ),
              _StatusCard(
                label: 'Bar Queue',
                value: '$barOrders',
                icon: Icons.local_bar,
                color: Colors.purple,
              ),
              _StatusCard(
                label: 'Completed',
                value: '$completedOrders',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Table Status
          const Text(
            'Table Status',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index] as Map<String, dynamic>;
                final name = table['name']?.toString() ?? 'Table ${table['id']}';
                final status = (table['status']?.toString() ?? 'available').toLowerCase();
                final color = switch (status) {
                  'occupied' => Colors.red,
                  'reserved' => Colors.blue,
                  'closed' => Colors.grey,
                  _ => Colors.green,
                };
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                        child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

