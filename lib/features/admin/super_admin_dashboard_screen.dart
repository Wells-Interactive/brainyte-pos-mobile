import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_response.dart';
import '../../core/constants/colors.dart';
import '../../core/api/endpoints.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  static const _endpoint = Endpoints.v1AdminRestaurants;

  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _chains = [];
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiClient.instance.get<Map<String, dynamic>>(
      _endpoint,
      queryParameters: _searchController.text.trim().isEmpty
          ? null
          : {'search': _searchController.text.trim()},
    );
    if (!mounted) return;
    if (!result.success || result.data == null) {
      setState(() {
        _loading = false;
        _error = result.error ?? 'Unable to load restaurants.';
      });
      return;
    }

    final restaurants = result.data!['restaurants'];
    final chains = result.data!['chains'];
    setState(() {
      _restaurants = restaurants is List
          ? restaurants
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
      _chains = chains is List
          ? chains
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
      _loading = false;
    });
  }

  Future<void> _createRestaurant() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreateRestaurantDialog(),
    );
    if (values == null) return;

    await _runAction(
      ApiClient.instance.post<Map<String, dynamic>>(_endpoint, body: values),
      successMessage: 'Restaurant created.',
    );
  }

  Future<void> _toggleRestaurant(Map<String, dynamic> restaurant) async {
    await _runAction(
      ApiClient.instance.patch<Map<String, dynamic>>(
        _endpoint,
        body: {'action': 'toggle', 'restaurant_id': restaurant['id']},
      ),
      successMessage: 'Restaurant status updated.',
    );
  }

  Future<void> _linkChain(Map<String, dynamic> restaurant, int? chainId) async {
    await _runAction(
      ApiClient.instance.patch<Map<String, dynamic>>(
        _endpoint,
        body: {
          'action': 'link_chain',
          'restaurant_id': restaurant['id'],
          'chain_id': chainId,
        },
      ),
      successMessage: 'Restaurant chain updated.',
    );
  }

  Future<void> _archiveRestaurant(Map<String, dynamic> restaurant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive restaurant?'),
        content: Text(
          'Archive ${restaurant['name']}? Its records will be retained and its users will no longer be able to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(
      ApiClient.instance.delete<Map<String, dynamic>>(
        _endpoint,
        body: {'restaurant_id': restaurant['id']},
      ),
      successMessage: 'Restaurant archived.',
    );
  }

  Future<void> _runAction(
    Future<ApiResponse<Map<String, dynamic>>> request, {
    required String successMessage,
  }) async {
    setState(() => _working = true);
    final result = await request;
    if (!mounted) return;
    setState(() => _working = false);
    if (result.success != true) {
      _showMessage(result.error?.toString() ?? 'The request failed.');
      return;
    }
    _showMessage(successMessage);
    await _loadRestaurants();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text('Restaurant Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _working ? null : _loadRestaurants,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _working ? null : _createRestaurant,
        icon: const Icon(Icons.add_business),
        label: const Text('Add restaurant'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRestaurants,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (_loading || _working) const LinearProgressIndicator(),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                _searchTimer?.cancel();
                _searchTimer = Timer(
                  const Duration(milliseconds: 300),
                  _loadRestaurants,
                );
              },
              decoration: InputDecoration(
                labelText: 'Search restaurants',
                hintText: 'Name, chain, email, phone, or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _loadRestaurants();
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadRestaurants,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (!_loading && _restaurants.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No matching restaurants.'),
                ),
              ),
            ..._restaurants.map(_restaurantCard),
          ],
        ),
      ),
    );
  }

  Widget _restaurantCard(Map<String, dynamic> restaurant) {
    final archived = restaurant['archived_at'] != null;
    final active =
        restaurant['is_active'] == 1 ||
        restaurant['is_active'] == true ||
        restaurant['is_active'] == '1';
    final selectedChainId = int.tryParse(
      restaurant['chain_id']?.toString() ?? '',
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    restaurant['name']?.toString() ?? 'Restaurant',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    archived
                        ? 'Archived'
                        : active
                        ? 'Active'
                        : 'Inactive',
                  ),
                  backgroundColor: archived
                      ? AppColors.textLight.withValues(alpha: 0.2)
                      : active
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                ),
              ],
            ),
            if ((restaurant['email']?.toString() ?? '').isNotEmpty)
              Text(restaurant['email'].toString()),
            if ((restaurant['address']?.toString() ?? '').isNotEmpty)
              Text(restaurant['address'].toString()),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue:
                        _chains.any(
                          (chain) =>
                              int.tryParse(chain['id'].toString()) ==
                              selectedChainId,
                        )
                        ? selectedChainId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Chain',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Independent'),
                      ),
                      ..._chains.map((chain) {
                        final id = int.parse(chain['id'].toString());
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(chain['name']?.toString() ?? 'Chain'),
                        );
                      }),
                    ],
                    onChanged: archived || _working
                        ? null
                        : (chainId) => _linkChain(restaurant, chainId),
                  ),
                ),
                const SizedBox(width: 8),
                if (!archived)
                  IconButton(
                    tooltip: active ? 'Deactivate' : 'Activate',
                    onPressed: _working
                        ? null
                        : () => _toggleRestaurant(restaurant),
                    icon: Icon(
                      active ? Icons.pause_circle : Icons.play_circle,
                      color: active ? AppColors.warning : AppColors.success,
                    ),
                  ),
                if (!archived)
                  IconButton(
                    tooltip: 'Archive',
                    onPressed: _working
                        ? null
                        : () => _archiveRestaurant(restaurant),
                    icon: const Icon(Icons.archive_outlined),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateRestaurantDialog extends StatefulWidget {
  const _CreateRestaurantDialog();

  @override
  State<_CreateRestaurantDialog> createState() =>
      _CreateRestaurantDialogState();
}

class _CreateRestaurantDialogState extends State<_CreateRestaurantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  final _chainName = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _ownerPassword.dispose();
    _chainName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add restaurant'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_name, 'Restaurant name'),
                _field(_ownerName, 'Owner name'),
                _field(
                  _ownerEmail,
                  'Owner email',
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  _ownerPassword,
                  'Owner password (8+ characters)',
                  obscure: true,
                ),
                _field(_chainName, 'Existing or new chain name (optional)'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'owner_name': _ownerName.text.trim(),
              'owner_email': _ownerEmail.text.trim(),
              'owner_password': _ownerPassword.text,
              'chain_name': _chainName.text.trim(),
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (controller == _chainName ||
              (controller == _ownerPassword && text.length >= 8)) {
            return null;
          }
          if (text.isEmpty) return 'This field is required.';
          if (controller == _ownerPassword && text.length < 8) {
            return 'Use at least 8 characters.';
          }
          if (controller == _ownerEmail && !text.contains('@')) {
            return 'Enter a valid email address.';
          }
          return null;
        },
      ),
    );
  }
}
