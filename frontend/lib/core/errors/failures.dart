import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'تحقق من اتصالك بالإنترنت'});
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({
    super.message = 'خطأ في الخادم، الرجاء المحاولة لاحقاً',
    this.statusCode,
  });

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'غير مصرح لك بهذا الإجراء'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'البيانات المطلوبة غير موجودة'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'خطأ في التخزين المحلي'});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'انتهت مهلة الاتصال'});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'حدث خطأ غير متوقع'});
}
