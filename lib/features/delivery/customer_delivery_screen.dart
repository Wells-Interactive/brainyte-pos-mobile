import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/currency.dart';
import '../../widgets/confirm_exit_scope.dart';
import '../../widgets/role_based_drawer.dart';

class CustomerDeliveryScreen extends StatefulWidget {
  const CustomerDeliveryScreen({super.key});

  @override
  State<CustomerDeliveryScreen> createState() => _CustomerDeliveryScreenState();
}

class _CustomerDeliveryScreenState extends State<CustomerDeliveryScreen> {
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _requests = TextEditingController();
  String _itemId = '';
  String _quantity = '1';
  String _paymentMethod = 'pending';
  List<dynamic> _menu = [];
  List<dynamic> _orders = [];
  bool _loading = true;
  bool _processingPayment = false;

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

    final body = {
      'action': 'create',
      'items': [
        {'menu_item_id': item, 'quantity': qty},
      ],
      'delivery_address': _address.text.trim(),
      'phone_number': _phone.text.trim(),
      'special_requests': _requests.text.trim(),
      'payment_method': _paymentMethod,
    };

    final r = await ApiClient.instance.post<Map<String, dynamic>>(
      Endpoints.v1Delivery,
      body: body,
    );

    if (!r.success) {
      _notice(r.error ?? 'Unable to submit request.');
      return;
    }

    final deliveryOrderId = r.data?['id'] ?? r.data?['delivery_order_id'];
    if (deliveryOrderId == null) {
      _notice('Delivery request submitted.');
      _load();
      return;
    }

    if (_paymentMethod == 'paystack') {
      await _initiatePaystackPayment((deliveryOrderId as num).toInt());
    } else {
      _notice('Delivery request submitted.');
      _load();
    }
  }

  Future<void> _initiatePaystackPayment(int deliveryOrderId) async {
    setState(() => _processingPayment = true);

    final result = await ApiClient.instance.post<Map<String, dynamic>>(
      Endpoints.v1Payments,
      body: {
        'action': 'initialize',
        'delivery_order_id': deliveryOrderId,
        'callback_url': 'brainytepos://paystack/callback',
      },
    );

    setState(() => _processingPayment = false);

    if (!result.success || result.data == null) {
      _notice(result.error ?? 'Unable to initialize payment');
      return;
    }

    final authUrl = result.data!['authorization_url'] as String?;
    final reference = result.data!['reference'] as String?;

    if (authUrl == null) {
      _notice('Payment initialization failed');
      return;
    }

    final uri = Uri.parse(authUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _notice('Unable to open payment page');
      return;
    }

    if (reference != null && mounted) {
      _pollPaymentStatus(deliveryOrderId, reference);
    }
  }

  Future<void> _pollPaymentStatus(int deliveryOrderId, String reference) async {
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      final result = await ApiClient.instance.post<Map<String, dynamic>>(
        Endpoints.v1Payments,
        body: {
          'action': 'verify',
          'reference': reference,
        },
      );

      if (result.success && result.data != null) {
        final status = (result.data!['status'] ?? '').toString();
        if (status == 'success') {
          _notice('Payment successful!');
          _load();
          return;
        } else if (status == 'failed') {
          _notice('Payment failed. Please try again.');
          return;
        }
      }
    }

    _notice('Payment pending. Check your orders for updates.');
    _load();
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
  Widget build(BuildContext context) {
    return ConfirmExitScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Home Delivery')),
        drawer: const RoleBasedDrawer(role: 'customer', currentRoute: '/delivery'),
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
                              child: Text('${m['name']} — ${CurrencyFormatter.format((m['price'] as num?)?.toDouble() ?? 0)}'),
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
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'pending',
                          label: Text('Cash on Delivery'),
                        ),
                        ButtonSegment(
                          value: 'paystack',
                          label: Text('Paystack'),
                        ),
                      ],
                      selected: {_paymentMethod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _paymentMethod = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _processingPayment ? null : _request,
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: _processingPayment
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _paymentMethod == 'paystack'
                                    ? 'Pay & Request'
                                    : 'Request delivery',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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
                            'Order #${o['id']} — ${CurrencyFormatter.format((o['total_amount'] as num?)?.toDouble() ?? 0)}',
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
}
