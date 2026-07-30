import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.initialize();
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
      title: 'Brainyte Restaurant POS',
      theme: AppTheme.light,
      initialRoute: AppRouter.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
