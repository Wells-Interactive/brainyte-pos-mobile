import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/admin_stats.dart';

class AdminRepository {
  const AdminRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<AdminStats>> fetchStats() async {
    // Try v1 reports endpoint first
    final result = await _client.get<Map<String, dynamic>>(
      Endpoints.v1Reports,
      queryParameters: {'scope': 'day', 'top_items': 10},
      onData: (data) => data,
    );

    if (result.success && result.data != null) {
      return ApiResponse.success(AdminStats.fromV1Json(result.data!), statusCode: result.statusCode);
    }

    // Fallback to legacy status endpoint
    final legacyResult = await _client.getLegacy('${Endpoints.legacyStatus}?stats=1');
    if (legacyResult.success && legacyResult.data != null) {
      return ApiResponse.success(AdminStats.fromJson(legacyResult.data!), statusCode: legacyResult.statusCode);
    }

    return ApiResponse.failure(
      legacyResult.error ?? result.error ?? 'Unable to load statistics',
      statusCode: legacyResult.statusCode ?? result.statusCode,
    );
  }
}
