import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/menu_item.dart';
import '../repositories/menu_repository.dart';

/// Repository provider for menu operations.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ApiClient.instance);
});

/// Provider that fetches and caches all menu items.
final menuListProvider = FutureProvider<List<MenuItem>>((ref) async {
  final repo = ref.watch(menuRepositoryProvider);
  final result = await repo.fetchMenu();
  if (result.success && result.data != null) {
    return result.data!;
  }
  throw Exception(result.error ?? 'Failed to load menu');
});

/// Simple mutable reference for the selected category filter.
class CategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String category) => state = category;
}

/// Provider for the selected menu category filter.
final selectedMenuCategoryProvider =
    NotifierProvider<CategoryFilterNotifier, String>(CategoryFilterNotifier.new);

/// Provider that returns menu items filtered by the selected category.
final filteredMenuProvider = Provider<List<MenuItem>>((ref) {
  final category = ref.watch(selectedMenuCategoryProvider);
  final menuAsync = ref.watch(menuListProvider);

  return menuAsync.when(
    data: (items) {
      if (category == 'all') return items;
      return items.where((item) => item.category == category).toList();
    },
    loading: () => const [],
    error: (_, __) => const [],
  );
});
