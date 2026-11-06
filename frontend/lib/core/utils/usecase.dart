import 'package:hurghada_winners/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

abstract class UseCaseNoParams<Result> {
  Future<Either<Failure, Result>> call();
}

class NoParams {
  const NoParams();
}
