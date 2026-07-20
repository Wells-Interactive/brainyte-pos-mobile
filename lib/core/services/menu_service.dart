import '../repositories/menu_repository.dart';
import '../api/api_client.dart';

class MenuService {
  MenuService() : repository = MenuRepository(ApiClient.instance);

  final MenuRepository repository;
}
