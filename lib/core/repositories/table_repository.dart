import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/table.dart';

class TableRepository {
  const TableRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<List<RestaurantTable>>> fetchTables() async {
    final result = await _client.get(Endpoints.status);
    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Unable to load tables', statusCode: result.statusCode);
    }

    final rawTables = result.data!['tables'] as List<dynamic>? ?? const <dynamic>[];
    final tables = rawTables
        .map((table) => RestaurantTable.fromJson(Map<String, dynamic>.from(table as Map)))
        .toList();

    return ApiResponse.success(tables, statusCode: result.statusCode);
  }
}
