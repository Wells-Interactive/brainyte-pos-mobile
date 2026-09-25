import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../widgets/role_based_drawer.dart';

class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key});
  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ApiClient.instance.get<Map<String, dynamic>>(
      Endpoints.v1Delivery,
    );
    if (mounted) {
      setState(() {
        _orders = result.data?['orders'] ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _post(dynamic order, String action, [String? status]) async {
    final body = <String, dynamic>{'action': action, 'id': order['id']};
    if (status != null) body['status'] = status;
    await ApiClient.instance.post<Map<String, dynamic>>(
      Endpoints.v1Delivery,
      body: body,
    );
    await _load();
  }

  Future<void> _shareLocation(dynamic order) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Turn on Location Services to share delivery location.',
            ),
          ),
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share delivery location?'),
            content: const Text(
              'Your location is used only while you choose to update an active delivery for the customer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (shouldRequest != true) return;
      }
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was not granted.')),
        );
      }
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission is blocked in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    await ApiClient.instance.post<Map<String, dynamic>>(
      Endpoints.v1Delivery,
      body: {
        'action': 'location',
        'id': order['id'],
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy_meters': position.accuracy,
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rider Deliveries')),
    drawer: const RoleBasedDrawer(
      role: 'rider',
      currentRoute: '/rider-delivery',
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: _orders.map(_card).toList(),
            ),
          ),
  );
  Widget _card(dynamic order) {
    final lat = double.tryParse('${order['latitude']}');
    final lng = double.tryParse('${order['longitude']}');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery #${order['id']} · ${order['status']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${order['customer_name'] ?? 'Customer'} · ${order['phone_number']}',
            ),
            Text('${order['delivery_address']}'),
            if (lat != null && lng != null)
              SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.brainyte.brainyte_restaurant_pos',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 42,
                          height: 42,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (order['rider_id'] == null)
                  OutlinedButton(
                    onPressed: () => _post(order, 'assign'),
                    child: const Text('Accept'),
                  ),
                if (order['rider_id'] != null) ...[
                  OutlinedButton(
                    onPressed: () => _shareLocation(order),
                    child: const Text('Share location'),
                  ),
                  OutlinedButton(
                    onPressed: () => _post(order, 'status', 'out_for_delivery'),
                    child: const Text('Out for delivery'),
                  ),
                  FilledButton(
                    onPressed: () => _post(order, 'status', 'delivered'),
                    child: const Text('Delivered'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
