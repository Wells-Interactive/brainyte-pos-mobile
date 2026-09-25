import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/table.dart';

class TableRepository {
  const TableRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<List<RestaurantTable>>> fetchTables() async {
    // Use v1 endpoint with Bearer token authentication
    final result = await _client.get(
      Endpoints.v1Status,
      onData: (data) {
        final rawTables = data['tables'] as List<dynamic>? ?? const <dynamic>[];
        return rawTables
            .map((table) => RestaurantTable.fromJson(Map<String, dynamic>.from(table as Map)))
            .toList();
      },
    );
    return result;
  }
}
