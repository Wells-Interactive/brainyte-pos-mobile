import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/connectivity_service.dart';
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
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'app',
        context: ErrorSummary('Unhandled exception'),
      ),
    );
    return true;
  };

  try {
    // Initialize API client
    await ApiClient.instance.initialize();

    // TODO: Re-enable Firebase after crash investigation
    // await FirebaseService().initialize();
  } catch (e, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'main',
        context: ErrorSummary('Failed to initialize app'),
      ),
    );
  }

  runApp(const ProviderScope(child: BrainytePosApp()));
}

class BrainytePosApp extends ConsumerStatefulWidget {
  const BrainytePosApp({super.key});

  @override
  ConsumerState<BrainytePosApp> createState() => _BrainytePosAppState();
}

class _BrainytePosAppState extends ConsumerState<BrainytePosApp>
    with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _connectivitySubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = ConnectivityService.instance.changes.listen((
      results,
    ) {
      final message = results.contains(ConnectivityResult.none)
          ? 'No internet connection. Check your network.'
          : 'Internet connection restored.';
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      scaffoldMessengerKey: _messengerKey,
      title: 'Brainyte_Pos',
      theme: AppTheme.light,
      home: const _SessionGate(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }

  Future<void> _onAppResumed() async {
    if (!ApiClient.instance.isAuthenticated) return;
    try {
      await ApiClient.instance.refreshTokens();
    } catch (_) {}
  }
}

class _SessionGate extends ConsumerWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStateProvider);

    if (!ApiClient.instance.isAuthenticated) {
      return const LoginScreen();
    }

    return role.when(
      data: (storedRole) {
        if (storedRole == null || storedRole.isEmpty) {
          return const LoginScreen();
        }
        return AppRouter.homeForRole(storedRole);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
    );
  }
}
