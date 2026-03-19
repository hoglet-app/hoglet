class PosthogApiError implements Exception {
  final int statusCode;
  final String message;

  PosthogApiError(this.statusCode, this.message);

  factory PosthogApiError.fromResponse(int statusCode, String body) {
    if (statusCode == 401 || statusCode == 403) {
      return AuthenticationError(statusCode, body);
    }
    if (statusCode == 429) {
      return RateLimitError(statusCode, body);
    }
    return PosthogApiError(statusCode, body);
  }

  @override
  String toString() => 'PosthogApiError($statusCode): $message';
}

class AuthenticationError extends PosthogApiError {
  AuthenticationError(super.statusCode, super.message);

  @override
  String toString() => 'AuthenticationError($statusCode): $message';
}

class RateLimitError extends PosthogApiError {
  final Duration? retryAfter;

  RateLimitError(super.statusCode, super.message, {this.retryAfter});

  factory RateLimitError.fromHeaders(
    int statusCode,
    String body,
    Map<String, String> headers,
  ) {
    Duration? retryAfter;
    final retryHeader = headers['retry-after'];
    if (retryHeader != null) {
      final seconds = int.tryParse(retryHeader);
      if (seconds != null) {
        retryAfter = Duration(seconds: seconds);
      }
    }
    return RateLimitError(statusCode, body, retryAfter: retryAfter);
  }

  @override
  String toString() =>
      'RateLimitError($statusCode): $message (retry after: $retryAfter)';
}

class NetworkError implements Exception {
  final String message;
  final Object? cause;

  NetworkError(this.message, {this.cause});

  @override
  String toString() => 'NetworkError: $message';
}
