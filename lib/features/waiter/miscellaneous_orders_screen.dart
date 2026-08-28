import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/models/table.dart';
import '../../core/repositories/table_repository.dart';
import '../../widgets/confirm_exit_scope.dart';

class MiscellaneousOrdersScreen extends StatefulWidget {
  const MiscellaneousOrdersScreen({super.key});

  @override
  State<MiscellaneousOrdersScreen> createState() => _MiscellaneousOrdersScreenState();
}

class _MiscellaneousOrdersScreenState extends State<MiscellaneousOrdersScreen> {
  final _apiClient = ApiClient.instance;
  final _tableRepository = TableRepository(ApiClient.instance);
  final _notesController = TextEditingController();
  List<dynamic> _activeMiscOrders = [];
  List<RestaurantTable> _tables = const [];
  int? _selectedPrimaryTableId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tablesResult = await _tableRepository.fetchTables();
    final miscResult = await _apiClient.get<Map<String, dynamic>>(
      Endpoints.v1Miscellaneous,
    );
    if (!mounted) return;
    setState(() {
      _tables = tablesResult.success && tablesResult.data != null
          ? tablesResult.data!
          : const [];
      _activeMiscOrders = miscResult.success && miscResult.data != null
          ? miscResult.data!['miscellaneous_orders'] as List<dynamic>? ?? const []
          : const [];
      _loading = false;
    });
  }

  Future<void> _createMiscOrder() async {
    if (_selectedPrimaryTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a primary table'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = await _apiClient.post<Map<String, dynamic>>(
      Endpoints.v1Miscellaneous,
      body: {
        'action': 'create',
        'primary_table_id': _selectedPrimaryTableId,
        'notes': _notesController.text.trim(),
      },
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (result.success) {
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Miscellaneous order created'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to create miscellaneous order'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _assignTable(int miscOrderId) async {
    final tableId = await showDialog<int>(
      context: context,
      builder: (context) => _TableSelectDialog(tables: _tables),
    );

    if (tableId == null || tableId <= 0) return;

    final result = await _apiClient.post<Map<String, dynamic>>(
      Endpoints.v1Miscellaneous,
      body: {
        'action': 'assign_table',
        'miscellaneous_order_id': miscOrderId,
        'table_id': tableId,
      },
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table assigned successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to assign table'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _completeOrder(int miscOrderId) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      Endpoints.v1Miscellaneous,
      body: {
        'action': 'complete',
        'miscellaneous_order_id': miscOrderId,
      },
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Miscellaneous order completed'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to complete order'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _cancelOrder(int miscOrderId) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      Endpoints.v1Miscellaneous,
      body: {
        'action': 'cancel',
        'miscellaneous_order_id': miscOrderId,
      },
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Miscellaneous order cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to cancel order'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Miscellaneous Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Miscellaneous Order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedPrimaryTableId,
                  decoration: const InputDecoration(
                    labelText: 'Primary Table',
                    prefixIcon: Icon(Icons.table_restaurant),
                  ),
                  items: _tables
                      .map(
                        (table) => DropdownMenuItem<int>(
                          value: table.id,
                          child: Text('${table.name} (${table.status})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPrimaryTableId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional notes about this miscellaneous order',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _createMiscOrder,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _submitting ? 'Creating...' : 'Create Miscellaneous Order',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Active Miscellaneous Orders',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        if (_activeMiscOrders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No active miscellaneous orders',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          )
        else
          ..._activeMiscOrders.map((misc) {
            final assignments = (misc['assignments'] as List<dynamic>? ?? const <dynamic>[]);
            final tableNames = assignments
                .map((a) => a['table_name']?.toString() ?? 'Table ${a['table_id']}')
                .toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  'Misc Order #${misc['id']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primary: ${misc['primary_table_name'] ?? 'Table ${misc['primary_table_id']}'}'),
                    if (tableNames.isNotEmpty)
                      Text('Assigned: ${tableNames.join(', ')}'),
                    if (misc['notes'] != null && misc['notes'].toString().isNotEmpty)
                      Text('Notes: ${misc['notes']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.blue),
                      tooltip: 'Assign Table',
                      onPressed: () => _assignTable((misc['id'] as num).toInt()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Complete',
                      onPressed: () => _completeOrder((misc['id'] as num).toInt()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Cancel',
                      onPressed: () => _cancelOrder((misc['id'] as num).toInt()),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _TableSelectDialog extends StatelessWidget {
  const _TableSelectDialog({required this.tables});

  final List<RestaurantTable> tables;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Table to Assign'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return ListTile(
              title: Text(table.name),
              subtitle: Text(table.status),
              onTap: () => Navigator.pop(context, table.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
