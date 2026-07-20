class ApiResponse<T> {
  const ApiResponse({required this.success, this.data, this.error, this.statusCode});

  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  factory ApiResponse.success(T data, {int? statusCode}) => ApiResponse<T>(
        success: true,
        data: data,
        statusCode: statusCode,
      );

  factory ApiResponse.failure(String error, {int? statusCode}) => ApiResponse<T>(
        success: false,
        error: error,
        statusCode: statusCode,
      );
}
