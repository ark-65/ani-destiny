import '../error/failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is ResultSuccess<T>;
  bool get isFailure => this is ResultFailure<T>;
}

class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);

  final T value;
}

class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;
}
