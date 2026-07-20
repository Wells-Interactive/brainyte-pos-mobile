import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/menu_item.dart';

class MenuRepository {
  const MenuRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<List<MenuItem>>> fetchMenu({String? category}) async {
    final result = await _client.get(
      Endpoints.menu,
      queryParameters: category == null ? null : {'category': category},
    );

    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Unable to load menu', statusCode: result.statusCode);
    }

    final rawItems = result.data!['items'] as List<dynamic>? ?? const <dynamic>[];
    final items = rawItems
        .map((item) => MenuItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return ApiResponse.success(items, statusCode: result.statusCode);
  }
}
