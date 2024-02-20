import 'dart:async';

import 'package:api_error_parser/api_error_parser.dart';
import 'package:network_utils/resource.dart';

typedef SaveCallResult<ResultType, RequestType> = Future<ResultType> Function(
    RequestType item);

typedef ShouldFetch<ResultType> = bool Function(ResultType data);

typedef LoadFromCache<ResultType> = Stream<ResultType> Function();

typedef CreateCall<RequestType> = Future<RequestType> Function();

typedef FetchFailed = void Function();

typedef PaginationCall = void Function(Pagination pagination);

class NetworkBoundResource<ResultType, RequestType, T> {
  final ApiParser<T> _apiParser;
  final SaveCallResult<ResultType, RequestType> saveCallResult;
  final ShouldFetch<ResultType> shouldFetch;
  final LoadFromCache<ResultType>? loadFromCache;
  final CreateCall createCall;
  FetchFailed? fetchFailed;
  PaginationCall? paginationCall;

  late StreamController _resourceStream;

  NetworkBoundResource(
    this._apiParser, {
    required this.createCall,
    required this.shouldFetch,
    required this.saveCallResult,
    this.loadFromCache,
    this.fetchFailed,
    this.paginationCall,
  }) {
    fetchFailed ??= () {};
    _resourceStream =
        StreamController<Resource<ResultType, T>>(onListen: _startListenStream);
  }

  void _startListenStream() {
    _resourceStream.add(Resource<ResultType, String>.loading(null));

    if (loadFromCache == null) {
      _fetchFromNetwork();
      return;
    }

    final streamFromCache = loadFromCache!();
    late StreamSubscription scanSubscription;
    scanSubscription = streamFromCache.listen((event) {
      scanSubscription.cancel();
      if (shouldFetch(event)) {
        _fetchFromNetwork();
      } else {
        _resourceStream.add(Resource<ResultType, String>.success(event));
      }
    });
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final dynamic apiResponse = await createCall();
      final parserResponse = _apiParser.parse(apiResponse as ApiResponse<RequestType>);
      if (parserResponse is ApiParserSuccessResponse<RequestType, T>) {
        if (parserResponse.pagination != null && paginationCall != null) {
          paginationCall!(parserResponse.pagination!);
        }
        _resourceStream.add(
          Resource<ResultType, String>.success(
            await saveCallResult(parserResponse.data),
            pagination: parserResponse.pagination,
          ),
        );
      } else if (parserResponse is ApiParserEmptyResponse<RequestType, T>) {
        _resourceStream.add(Resource<ResultType, String>.success(null));
      } else {
        fetchFailed!();
        _resourceStream.add(
          Resource<ResultType, String>.errorList(
            null,
            (parserResponse as ApiParserErrorResponse<RequestType, String>)
                .errors,
          ),
        );
      }
    } on Exception catch (e) {
      fetchFailed!();
      if (e is Error) {
        _resourceStream
            .add(Resource<ResultType, String>.error(null, e.toString()));
      } else {
        _resourceStream
            .add(Resource<ResultType, String>.errorException(null, e));
      }
    }
  }

  Stream<Resource<ResultType, T>> asStream() {
    return _resourceStream.stream as Stream<Resource<ResultType, T>>;
  }
}
