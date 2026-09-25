import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'firebase_messaging_service.dart';

/// Service for initializing and managing Firebase services.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  bool _isInitialized = false;

  /// Initialize Firebase and all related services.
  /// Should be called early in app startup (e.g., in main()).
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Firebase already initialized');
      return;
    }

    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');

      // Initialize Crashlytics
      if (!kDebugMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        debugPrint('Crashlytics initialized');
      }

      // Initialize Performance Monitoring
      try {
        FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
        debugPrint('Performance Monitoring initialized');
      } catch (e) {
        debugPrint('Performance Monitoring initialization failed: $e');
      }

      // Initialize Firebase Messaging
      try {
        await _messagingService.initialize();
        debugPrint('Firebase Messaging initialized');
      } catch (e) {
        debugPrint('Firebase Messaging initialization failed: $e');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      // Firebase initialization failed - continue without it
      // This allows the app to function even if Firebase is not configured
    }
  }

  /// Check if Firebase is initialized.
  bool get isInitialized => _isInitialized;

  /// Get the Firebase messaging service.
  FirebaseMessagingService get messaging => _messagingService;

  /// Get the Firebase Crashlytics instance.
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  /// Get the Firebase Performance Monitoring instance.
  FirebasePerformance get performance => FirebasePerformance.instance;

  /// Log a non-fatal error to Crashlytics.
  void logError(dynamic error, [StackTrace? stack]) {
    if (_isInitialized && !kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
  }

  /// Log a message to Crashlytics.
  void logMessage(String message) {
    if (_isInitialized && !kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Set user identifier for Crashlytics.
  void setUserIdentifier(String identifier) {
    if (_isInitialized && !kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    }
  }
}