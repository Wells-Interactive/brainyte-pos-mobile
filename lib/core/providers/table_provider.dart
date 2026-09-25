import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/table.dart';
import '../repositories/table_repository.dart';

/// Repository provider for table operations.
final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ApiClient.instance);
});

/// Provider that fetches the list of restaurant tables.
final tableListProvider = FutureProvider<List<RestaurantTable>>((ref) async {
  final repo = ref.watch(tableRepositoryProvider);
  final result = await repo.fetchTables();
  if (result.success && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load tables');
});

/// Simple mutable reference for the selected table.
class SelectedTableNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? tableId) => state = tableId;
}

/// Provider for the currently selected table ID.
final selectedTableProvider = NotifierProvider<SelectedTableNotifier, int?>(SelectedTableNotifier.new);
