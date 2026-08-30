import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
// TODO: Re-enable Firebase after crash investigation
// import 'core/services/firebase_service.dart';
import 'routing/app_router.dart';
import 'features/login/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler - set up BEFORE any async initialization
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'app',
      context: ErrorSummary('Unhandled exception'),
    ));
    return true;
  };

  try {
    // Initialize API client
    await ApiClient.instance.initialize();

    // TODO: Re-enable Firebase after crash investigation
    // await FirebaseService().initialize();
  } catch (e, stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: e,
      stack: stack,
      library: 'main',
      context: ErrorSummary('Failed to initialize app'),
    ));
  }

  runApp(const ProviderScope(child: BrainytePosApp()));
}

class BrainytePosApp extends ConsumerWidget {
  const BrainytePosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes to redirect to login when logged out
    ref.listen<AsyncValue<String?>>(authStateProvider, (previous, next) {
      if (!next.isLoading && !next.hasValue) {
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
