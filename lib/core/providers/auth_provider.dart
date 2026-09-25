import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../repositories/auth_repository.dart';

/// Provider for the AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ApiClient.instance);
});

/// Provider for the current authentication state.
/// Returns null if not authenticated, or the user's role if authenticated.
final authStateProvider = FutureProvider<String?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getStoredRole();
});

/// Provider that checks whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ApiClient.instance.isAuthenticated;
});

/// Provider for the user's display name.
final userNameProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getStoredUserName();
});

/// Logout action provider - clears session.
final logoutProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  await repo.logout();
});
