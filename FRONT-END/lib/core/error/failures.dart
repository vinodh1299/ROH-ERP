abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed. Please check your internet.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired. Please log in again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server encountered an error. Please try again.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
