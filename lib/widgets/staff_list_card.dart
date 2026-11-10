import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../core/api/endpoints.dart';

class StaffListCard extends StatefulWidget {
  const StaffListCard({super.key});

  @override
  State<StaffListCard> createState() => _StaffListCardState();
}

class _StaffListCardState extends State<StaffListCard> {
  late Future<ApiResponse<Map<String, dynamic>>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _staffFuture = _loadStaff();
  }

  Future<ApiResponse<Map<String, dynamic>>> _loadStaff() {
    return ApiClient.instance.get<Map<String, dynamic>>(
      Endpoints.v1AdminStaff,
      onData: (data) => data,
    );
  }

  void _refresh() {
    setState(() => _staffFuture = _loadStaff());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Staff Accounts',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'Refresh staff',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            FutureBuilder<ApiResponse<Map<String, dynamic>>>(
              future: _staffFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final result = snapshot.data;
                if (result == null || !result.success || result.data == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      result?.error ?? 'Unable to load staff accounts.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                final staff = result.data!['staff'];
                if (staff is! List || staff.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No staff accounts found.'),
                  );
                }

                return Column(
                  children: staff.map((entry) {
                    if (entry is! Map<String, dynamic>) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(entry['name']?.toString() ?? 'Staff member'),
                      subtitle: Text(entry['email']?.toString() ?? ''),
                      trailing: Text(
                        (entry['role']?.toString() ?? '').toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
