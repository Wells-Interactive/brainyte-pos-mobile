import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final _apiClient = ApiClient.instance;
  List<dynamic> _customers = const [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      Endpoints.v1AdminCustomers,
      queryParameters: _searchQuery.isNotEmpty ? {'search': _searchQuery} : null,
    );
    if (!mounted) return;
    setState(() {
      if (result.success && result.data != null) {
        _customers = result.data!['customers'] as List<dynamic>? ?? const [];
      } else {
        _customers = const [];
      }
      _loading = false;
    });
  }

  Future<void> _toggleBan(int customerId, bool currentBanStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentBanStatus ? 'Unban Customer' : 'Ban Customer'),
        content: Text(
          currentBanStatus
              ? 'Are you sure you want to unban this customer?'
              : 'Are you sure you want to ban this customer? They will not be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: currentBanStatus ? Colors.green : Colors.red,
            ),
            child: Text(currentBanStatus ? 'Unban' : 'Ban'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _apiClient.post<Map<String, dynamic>>(
      Endpoints.v1AdminCustomers,
      body: {
        'customer_id': customerId,
        'ban': !currentBanStatus,
      },
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data?['message'] ?? 'Customer updated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCustomers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to update customer'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search customers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadCustomers();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          final isBanned = customer['banned'] == true || customer['banned'] == 1 || customer['banned'] == '1';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isBanned ? Colors.red : Colors.green,
                                child: Icon(
                                  isBanned ? Icons.block : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                customer['name']?.toString() ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer['email']?.toString() ?? ''),
                                  if (customer['phone_number'] != null)
                                    Text(customer['phone_number'].toString()),
                                ],
                              ),
                              trailing: Switch(
                                value: isBanned,
                                onChanged: (_) => _toggleBan(
                                  (customer['id'] as num).toInt(),
                                  isBanned,
                                ),
                              ),
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
