import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/menu_item.dart';

class MenuRepository {
  const MenuRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<List<MenuItem>>> fetchMenu({String? category}) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final result = await _client.get<Map<String, dynamic>>(
      Endpoints.v1Menu,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      onData: (data) => data,
    );

    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Unable to load menu', statusCode: result.statusCode);
    }

    return _parseMenuItems(result.data!);
  }

  Future<ApiResponse<List<MenuItem>>> _parseMenuItems(Map<String, dynamic> responseData) async {
    final rawItems = responseData['items'] as List<dynamic>?;

    if (rawItems != null) {
      final items = rawItems
          .map((item) => MenuItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      return ApiResponse.success(items);
    }

    final dataField = responseData['data'];
    if (dataField is List) {
      final items = dataField
          .map((item) => MenuItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      return ApiResponse.success(items);
    }

    return ApiResponse.success([]);
  }

  Future<ApiResponse<MenuItem>> fetchMenuItem(int id) async {
    final result = await _client.get<Map<String, dynamic>>(
      '${Endpoints.v1Menu}?id=$id',
      onData: (data) => data,
    );

    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Item not found', statusCode: result.statusCode);
    }

    final data = result.data!;
    final itemData = (data['data'] as Map<String, dynamic>?) ?? data;
    return ApiResponse.success(MenuItem.fromJson(itemData), statusCode: result.statusCode);
  }
}
