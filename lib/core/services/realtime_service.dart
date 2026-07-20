import 'dart:async';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../constants/app_constants.dart';

/// RealtimeService provides live updates using Server-Sent Events (SSE)
/// with a fallback to automatic polling every 5 seconds.
class RealtimeService {
  RealtimeService({this.role = 'kitchen'});

  final String role;

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  CancelToken? _cancelToken;
  Timer? _pollTimer;
  bool _disposed = false;

  Future<void> start() async {
    try {
      await _startSSE();
    } catch (_) {
      _startPolling();
    }
  }

  Future<void> _startSSE() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 0),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    _cancelToken = CancelToken();

    try {
      await dio.get(
        '${Endpoints.liveEvents}?role=$role',
        options: Options(
          responseType: ResponseType.stream,
        ),
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }
      _startPolling();
    }
  }

  void _startPolling() {
    if (_disposed) return;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_disposed) return;

      try {
        final response = await ApiClient.instance.get(Endpoints.status);
        if (response.success && response.data != null) {
          _controller.add(response.data!);
        }
      } catch (_) {}
    });
  }

  Future<void> stop() async {
    _disposed = true;
    _pollTimer?.cancel();
    _cancelToken?.cancel();
    await _controller.close();
  }

  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _cancelToken?.cancel();
    _controller.close();
  }
}
