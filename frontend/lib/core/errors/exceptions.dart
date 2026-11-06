class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'تحقق من اتصالك بالإنترنت'});
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'خطأ في الخادم',
    super.statusCode,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'غير مصرح لك بهذا الإجراء',
    super.statusCode = 401,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'البيانات المطلوبة غير موجودة',
    super.statusCode = 404,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 422,
  });
}

class CacheException extends AppException {
  const CacheException({super.message = 'خطأ في التخزين المحلي'});
}

class TimeoutException extends AppException {
  const TimeoutException({super.message = 'انتهت مهلة الاتصال'});
}
