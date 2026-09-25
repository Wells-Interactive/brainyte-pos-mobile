import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/currency.dart';

class CustomerBillingScreen extends StatefulWidget {
  const CustomerBillingScreen({super.key});

  @override
  State<CustomerBillingScreen> createState() => _CustomerBillingScreenState();
}

class _CustomerBillingScreenState extends State<CustomerBillingScreen> {
  final _apiClient = ApiClient.instance;
  List<dynamic> _transactions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      Endpoints.v1CustomerBilling,
    );
    if (!mounted) return;
    setState(() {
      if (result.success && result.data != null) {
        _transactions = result.data!['transactions'] as List<dynamic>? ?? const [];
      } else {
        _transactions = const [];
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBilling,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _transactions.isEmpty
                ? const Center(
                    child: Text('No transactions yet'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0;
                      final status = (tx['payment_status'] ?? tx['delivery_status'] ?? 'pending').toString();
                      final date = (tx['created_at'] ?? '').toString().split(' ').first;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: status == 'success' || status == 'delivered'
                                ? Colors.green
                                : Colors.orange,
                            child: Icon(
                              status == 'success' || status == 'delivered'
                                  ? Icons.check
                                  : Icons.pending,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            'Order #${tx['delivery_order_id']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('$date • $status'),
                          trailing: Text(
                            CurrencyFormatter.format(amount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
