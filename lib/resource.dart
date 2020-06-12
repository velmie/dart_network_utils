import 'package:api_error_parser/api_error_parser.dart';

enum Status { success, error, loading }

class Resource<T, E> {
  final Status status;
  final T data;
  final Pagination pagination;
  final Exception exception;
  final String errorMessage;
  final List<ParserMessageEntity<E>> errors;

  Resource._(this.status, this.data, this.pagination, this.exception, this.errorMessage, this.errors);

  factory Resource.loading(T data) {
    return Resource._(Status.loading, data, null, null, null, null);
  }

  factory Resource.success(T data, {Pagination pagination}) {
    return Resource._(Status.success, data, pagination, null, null, null);
  }

  factory Resource.error(T data, String errorMessage) {
    return Resource._(Status.error, data, null, null, errorMessage, null);
  }

  factory Resource.errorException(T data, Exception exception) {
    return Resource._(Status.error, data, null, exception, null, null);
  }

  factory Resource.errorList(T data, List<ParserMessageEntity<E>> errors) {
    return Resource._(Status.error, data, null, null, null, errors);
  }

  @override
  String toString() {
    return "{ ${super.toString()} status = $status, data = $data, pagination = $pagination, exception = $exception, errorMessage = $errorMessage, errors = $errors}";
  }
}
