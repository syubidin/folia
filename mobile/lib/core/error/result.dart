sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

sealed class Failure {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class AuthFailure extends Failure {
  const AuthFailure();
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure();
}

final class ValidationFailure extends Failure {
  const ValidationFailure();
}

final class RateLimitedFailure extends Failure {
  const RateLimitedFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class ServerFailure extends Failure {
  const ServerFailure();
}
