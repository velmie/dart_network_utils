import 'package:api_error_parser/api_error_parser.dart';

enum Status { success, error, loading }

class Resource<T, E> {
  final Status status;
  final T data;
  final Exception exception;
  final String errorMessage;
  final List<ParserMessageEntity<E>> errors;

  Resource._(
      this.status, this.data, this.exception, this.errorMessage, this.errors);

  factory Resource.loading(T data) {
    return Resource._(Status.loading, data, null, null, null);
  }

  factory Resource.success(T data) {
    return Resource._(Status.success, data, null, null, null);
  }

  factory Resource.error(T data, String errorMessage) {
    return Resource._(Status.error, data, null, errorMessage, null);
  }

  factory Resource.errorException(T data, Exception exception) {
    return Resource._(Status.error, data, exception, null, null);
  }

  factory Resource.errorList(T data, List<ParserMessageEntity<E>> errors) {
    return Resource._(Status.error, data, null, null, errors);
  }

  @override
  String toString() {
    return "{ ${super.toString()} status = $status, data = $data, exception = $exception, errorMessage = $errorMessage, errors = $errors}";
  }
}
