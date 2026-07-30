import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import 'menu_provider.dart';

/// Repository provider for order operations.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ApiClient.instance);
});

/// Cart state: maps menu_item_id to quantity.
final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);

/// Notifier for managing cart state (add, remove, clear items).
class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  void addItem(int menuItemId) {
    state = {...state, menuItemId: (state[menuItemId] ?? 0) + 1};
  }

  void removeItem(int menuItemId) {
    final current = state[menuItemId] ?? 0;
    if (current <= 1) {
      final newState = Map<int, int>.from(state);
      newState.remove(menuItemId);
      state = newState;
    } else {
      state = {...state, menuItemId: current - 1};
    }
  }

  void clearItem(int menuItemId) {
    final newState = Map<int, int>.from(state);
    newState.remove(menuItemId);
    state = newState;
  }

  void clearAll() {
    state = {};
  }
}

/// Computed total number of items in the cart.
final cartItemsCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0, (sum, qty) => sum + qty);
});

/// Computed grand total price from cart items.
final cartGrandTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final menuAsync = ref.watch(menuListProvider);
  final menu = menuAsync.when(
    data: (items) => items,
    loading: () => const [],
    error: (_, __) => const [],
  );

  return cart.entries.fold<double>(0, (sum, entry) {
    final item = menu.firstWhere(
      (menuItem) => menuItem.id == entry.key,
      orElse: () => const MenuItem(
        id: 0, name: '', description: '', price: 0, category: '',
      ),
    );
    return sum + (item.price * entry.value);
  });
});

/// Simple mutable reference for order instructions.
class InstructionsNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String instructions) => state = instructions;
}

/// Provider for order instructions (special notes).
final orderInstructionsProvider = NotifierProvider<InstructionsNotifier, String>(InstructionsNotifier.new);

/// Simple mutable reference for selected table ID.
class SelectedTableNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? tableId) => state = tableId;
}

/// Provider for the currently selected table ID.
final selectedTableIdProvider = NotifierProvider<SelectedTableNotifier, int?>(SelectedTableNotifier.new);

/// Provider for active orders list.
final activeOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final result = await repo.fetchOrders();
  if (result.success && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load orders');
});
