import 'dart:async';

import 'package:api_error_parser/api_error_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:network_utils/resource.dart';

typedef SaveCallResult<ResultType, RequestType> = Future<ResultType> Function(RequestType item);

typedef ShouldFetch<ResultType> = bool Function(ResultType data);

typedef LoadFromCache<ResultType> = Stream<ResultType> Function();

typedef CreateCall<RequestType> = Future<RequestType> Function();

typedef FetchFailed = void Function();

typedef PaginationCall = void Function(Pagination pagination);

class NetworkBoundResource<ResultType, RequestType, T> {
  final ApiParser<T> _apiParser;
  final SaveCallResult<ResultType, RequestType> saveCallResult;
  final ShouldFetch<ResultType> shouldFetch;
  final LoadFromCache<ResultType> loadFromCache;
  final CreateCall createCall;
  FetchFailed fetchFailed;
  PaginationCall paginationCall;

  StreamController _resourceStream;

  NetworkBoundResource(this._apiParser,
      {@required this.saveCallResult,
      @required this.shouldFetch,
      @required this.loadFromCache,
      @required this.createCall,
      this.fetchFailed,
      this.paginationCall})
      : assert(saveCallResult != null),
        assert(shouldFetch != null),
        assert(loadFromCache != null),
        assert(createCall != null) {
    if (fetchFailed == null) {
      fetchFailed = () => {};
    }
    _resourceStream = StreamController<Resource<ResultType, T>>(onListen: () {
      _startListenStream();
    });
  }

  void _startListenStream() {
    _resourceStream.add(Resource<ResultType, String>.loading(null));
    var streamFromCache = this.loadFromCache();

    if (streamFromCache != null) {
      StreamSubscription scanSubscription;
      scanSubscription = streamFromCache.listen((event) {
        scanSubscription.cancel();
        if (this.shouldFetch(event)) {
          _fetchFromNetwork();
        } else {
          _resourceStream.add(Resource<ResultType, String>.success(event));
        }
      });
    } else {
      _fetchFromNetwork();
    }
  }

  void _fetchFromNetwork() async {
    try {
      final apiResponse = await createCall();
      final ApiParserResponse<RequestType, T> parserResponse = _apiParser.parse(apiResponse);
      if (parserResponse is ApiParserSuccessResponse<RequestType, T>) {
        if (parserResponse.pagination != null) {
          paginationCall(parserResponse.pagination);
        }
        _resourceStream.add(Resource<ResultType, String>.success(await saveCallResult(parserResponse.data),
            pagination: parserResponse.pagination));
      } else if (parserResponse is ApiParserEmptyResponse<RequestType, T>) {
        _resourceStream.add(Resource<ResultType, String>.success(await saveCallResult(null)));
      } else {
        fetchFailed();
        _resourceStream.add(Resource<ResultType, String>.errorList(null, (parserResponse as ApiParserErrorResponse).errors));
      }
    } catch (e) {
      fetchFailed();
      if (e is Error) {
        _resourceStream.add(Resource<ResultType, String>.error(null, e.toString()));
      } else {
        _resourceStream.add(Resource<ResultType, String>.errorException(null, e));
      }
    }
  }

  Stream<Resource<ResultType, T>> asStream() {
    return _resourceStream.stream;
  }
}
