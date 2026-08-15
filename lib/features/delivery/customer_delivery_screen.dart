import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../widgets/confirm_exit_scope.dart';

class CustomerDeliveryScreen extends StatefulWidget {
  const CustomerDeliveryScreen({super.key});
  @override
  State<CustomerDeliveryScreen> createState() => _CustomerDeliveryScreenState();
}

class _CustomerDeliveryScreenState extends State<CustomerDeliveryScreen> {
  final _address = TextEditingController(),
      _phone = TextEditingController(),
      _requests = TextEditingController();
  String _itemId = '', _quantity = '1';
  List<dynamic> _menu = [], _orders = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final menu = await ApiClient.instance.get<Map<String, dynamic>>(
      Endpoints.v1Menu,
    );
    final orders = await ApiClient.instance.get<Map<String, dynamic>>(
      Endpoints.v1Delivery,
    );
    if (mounted) {
      setState(() {
        _menu = menu.data?['items'] ?? [];
        _orders = orders.data?['orders'] ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _request() async {
    final item = int.tryParse(_itemId), qty = int.tryParse(_quantity);
    if (item == null ||
        qty == null ||
        _address.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      return _notice('Complete all delivery details.');
    }
    final r = await ApiClient.instance.post<Map<String, dynamic>>(
      Endpoints.v1Delivery,
      body: {
        'action': 'create',
        'items': [
          {'menu_item_id': item, 'quantity': qty},
        ],
        'delivery_address': _address.text.trim(),
        'phone_number': _phone.text.trim(),
        'special_requests': _requests.text.trim(),
      },
    );
    _notice(
      r.success
          ? 'Delivery request submitted.'
          : r.error ?? 'Unable to submit request.',
    );
    if (r.success) _load();
  }

  void _notice(String t) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _requests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConfirmExitScope(
    child: Scaffold(
      appBar: AppBar(title: const Text('Home Delivery')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Request delivery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _itemId.isEmpty ? null : _itemId,
                    decoration: const InputDecoration(labelText: 'Menu item'),
                    items: _menu
                        .map(
                          (m) => DropdownMenuItem(
                            value: '${m['id']}',
                            child: Text('${m['name']} — ₦${m['price']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _itemId = v ?? ''),
                  ),
                  TextField(
                    onChanged: (v) => _quantity = v,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  TextField(
                    controller: _address,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                    ),
                  ),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
                  ),
                  TextField(
                    controller: _requests,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Special requests',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _request,
                    child: const Text('Request delivery'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'My delivery orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ..._orders.map(
                    (o) => Card(
                      child: ListTile(
                        title: Text(
                          'Order #${o['id']} — ₦${o['total_amount']}',
                        ),
                        subtitle: Text(
                          '${o['status']}\n${o['delivery_address']}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
