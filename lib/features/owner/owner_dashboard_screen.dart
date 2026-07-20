import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/repositories/admin_repository.dart';
import '../../core/models/admin_stats.dart';
import '../../core/utils/currency.dart';
import '../../widgets/loading_indicator.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _adminRepository = AdminRepository(ApiClient.instance);
  AdminStats? _stats;
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
    final result = await _adminRepository.fetchStats();
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
    await ApiClient.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const LoadingIndicator()
          : _stats == null
              ? const Center(child: Text('Unable to load analytics'))
              : _buildContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.star, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text('Owner Panel', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text('Full Business Overview', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Highlight Card
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Revenue", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(_stats!.revenueToday),
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('${_stats!.ordersToday} orders today', style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _StatCard(label: 'Orders Today', value: '${_stats!.ordersToday}', icon: Icons.receipt, color: Colors.blue),
                _StatCard(label: 'Revenue Today', value: CurrencyFormatter.format(_stats!.revenueToday), icon: Icons.attach_money, color: Colors.green),
                _StatCard(label: 'Occupied Tables', value: '${_stats!.occupiedTables}', icon: Icons.table_bar, color: Colors.orange),
                _StatCard(label: 'Available Tables', value: '${_stats!.availableTables}', icon: Icons.table_bar_outlined, color: Colors.green),
                _StatCard(label: 'Kitchen Queue', value: '${_stats!.kitchenQueue}', icon: Icons.kitchen, color: Colors.blue),
                _StatCard(label: 'Bar Queue', value: '${_stats!.barQueue}', icon: Icons.local_bar, color: Colors.purple),
                _StatCard(label: 'Active Waiters', value: '${_stats!.activeWaiters}', icon: Icons.person, color: Colors.teal),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Orders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    ..._stats!.recentOrders.map((order) => ListTile(
                          leading: const Icon(Icons.receipt_outlined),
                          title: Text('Order #${order['order_id']}'),
                          subtitle: Text('Table ${order['table_id']}'),
                          trailing: Text(
                            CurrencyFormatter.format((order['revenue'] as num?)?.toDouble() ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        )),
                    if (_stats!.recentOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No completed orders yet')),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

