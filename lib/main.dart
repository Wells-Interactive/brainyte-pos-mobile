import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/firebase_service.dart';
import 'routing/app_router.dart';
import 'features/login/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API client
  await ApiClient.instance.initialize();
  
  // Initialize Firebase (non-blocking, continues if fails)
  await FirebaseService().initialize();
  
  runApp(const ProviderScope(child: BrainytePosApp()));
}

class BrainytePosApp extends ConsumerWidget {
  const BrainytePosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading && next.hasValue && next.value == null) {
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != null && currentRoute != AppRouter.login) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      }
    });

    return MaterialApp(
      title: 'Brainyte_Pos',
      theme: AppTheme.light,
      home: const LoginScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
