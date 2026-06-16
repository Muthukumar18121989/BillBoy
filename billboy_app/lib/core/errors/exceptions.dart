class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection']);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}

class OcrException implements Exception {
  final String message;
  OcrException([this.message = 'OCR processing failed']);
}

class StorageException implements Exception {
  final String message;
  StorageException([this.message = 'Storage error']);
}
