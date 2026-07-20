import '../repositories/auth_repository.dart';
import '../api/api_client.dart';

class AuthService {
  AuthService() : repository = AuthRepository(ApiClient.instance);

  final AuthRepository repository;

  Future<String?> getStoredRole() => repository.getStoredRole();
  Future<String?> getStoredUserName() => repository.getStoredUserName();
}
