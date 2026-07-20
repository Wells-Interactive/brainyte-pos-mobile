import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/admin_stats.dart';

class AdminRepository {
  const AdminRepository(this._client);

  final ApiClient _client;

  Future<ApiResponse<AdminStats>> fetchStats() async {
    final result = await _client.get('${Endpoints.status}?stats=1');
    if (!result.success || result.data == null) {
      return ApiResponse.failure(result.error ?? 'Unable to load statistics', statusCode: result.statusCode);
    }

    return ApiResponse.success(AdminStats.fromJson(result.data!), statusCode: result.statusCode);
  }
}
