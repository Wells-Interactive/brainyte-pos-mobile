import '../repositories/menu_repository.dart';
import '../api/api_client.dart';
import '../models/menu_item.dart';
import '../api/api_response.dart';

class MenuService {
  MenuService() : repository = MenuRepository(ApiClient.instance);

  final MenuRepository repository;

  /// Cached menu items to avoid unnecessary API calls.
  List<MenuItem>? _cachedMenu;
  String? _cachedCategory;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetch menu items with optional category filter.
  /// Results are cached in memory for 5 minutes.
  Future<ApiResponse<List<MenuItem>>> fetchMenu({String? category, bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh && _cachedMenu != null && _cachedCategory == category && _cacheTime != null) {
      final elapsed = DateTime.now().difference(_cacheTime!);
      if (elapsed < _cacheDuration) {
        return ApiResponse.success(_cachedMenu!);
      }
    }

    final result = await repository.fetchMenu(category: category);

    if (result.success && result.data != null) {
      _cachedMenu = result.data;
      _cachedCategory = category;
      _cacheTime = DateTime.now();
    }

    return result;
  }

  /// Clear menu cache.
  void clearCache() {
    _cachedMenu = null;
    _cachedCategory = null;
    _cacheTime = null;
  }
}
