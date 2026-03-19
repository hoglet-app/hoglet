class PosthogApiError implements Exception {
  PosthogApiError(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'PosthogApiError($statusCode): $message';
}

class AuthenticationError extends PosthogApiError {
  AuthenticationError(super.statusCode, super.message);
}

class RateLimitError extends PosthogApiError {
  RateLimitError(super.statusCode, super.message, {this.retryAfterSeconds});
  final int? retryAfterSeconds;
}

class NetworkError implements Exception {
  NetworkError(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'NetworkError: $message';
}
