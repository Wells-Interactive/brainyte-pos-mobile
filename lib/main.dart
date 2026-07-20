import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.initialize();
  runApp(const ProviderScope(child: BrainytePosApp()));
}

class BrainytePosApp extends StatelessWidget {
  const BrainytePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brainyte Restaurant POS',
      theme: AppTheme.light,
      initialRoute: AppRouter.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
