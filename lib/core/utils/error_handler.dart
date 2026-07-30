import 'package:dio/dio.dart';

/// Centralized error handler for the Brainyte POS app.
///
/// Maps technical exceptions to user-friendly messages with emojis.
/// All screens should use [getFriendlyError] instead of displaying raw errors.
class ErrorHandler {
  /// Returns a user-friendly error message for the given error object.
  ///
  /// Handles:
  /// - DioException (timeouts, connection errors, bad responses)
  /// - FormatException (malformed responses)
  /// - SocketException (network issues)
  /// - Unknown errors
  static String getFriendlyError(Object error) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is FormatException) {
      return '⚠️ We received an unexpected response. Please try again.';
    }

    // Fallback for any other exception type
    return '⚠️ Something went wrong. Please try again.';
  }

  /// Handles specific DioException types with user-friendly messages.
  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '📶 Unable to connect to the server. Please try again.';

      case DioExceptionType.sendTimeout:
        return '⏳ Network request timed out. Please check your connection.';

      case DioExceptionType.receiveTimeout:
        return '⏳ The server is taking too long to respond.';

      case DioExceptionType.connectionError:
        return '📶 No internet connection. Please check your network.';

      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);

      case DioExceptionType.cancel:
        return '⚠️ Request was cancelled.';

      case DioExceptionType.badCertificate:
        return '🔒 Connection is not secure. Please contact your administrator.';

      case DioExceptionType.unknown:
        // Check for SocketException or other underlying errors
        final innerError = error.error;
        if (innerError != null) {
          final message = innerError.toString().toLowerCase();
          if (message.contains('socketexception') || message.contains('connection refused') || message.contains('connection reset')) {
            return '📶 No internet connection. Please check your network.';
          }
          if (message.contains('timeout')) {
            return '⏳ Connection timed out. Please try again.';
          }
        }
        return '⚠️ Something went wrong. Please try again.';

      case DioExceptionType.transformTimeout:
        return '⏳ Data processing timed out. Please try again.';
    }
  }

  /// Maps HTTP status codes to user-friendly messages.
  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '⚠️ Invalid request. Please check your input.';
      case 401:
        return '🔐 Incorrect email or password.';
      case 403:
        return '🚫 You don\'t have permission to perform this action.';
      case 404:
        return '🔍 Service unavailable. Please try again later.';
      case 422:
        return '⚠️ Please check your input and try again.';
      case 429:
        return '⏳ Too many requests. Please wait a moment.';
      case 500:
        return '🚫 Something went wrong on our server. Please try again later.';
      case 502:
      case 503:
        return '🚫 Server unavailable. Please contact your administrator if the problem continues.';
      default:
        if (statusCode != null && statusCode >= 500) {
          return '🚫 Something went wrong on our server. Please try again later.';
        }
        return '⚠️ Request failed. Please try again.';
    }
  }

  /// Returns a connection lost / reconnecting message for real-time updates.
  static String get connectionLost => '🔄 Connection lost. Reconnecting...';

  /// Returns a sign-in failure message.
  static String get signInFailed => '⚠️ Unable to sign in. Please try again.';
}

