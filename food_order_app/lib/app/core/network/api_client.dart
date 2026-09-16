import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final GetStorage _storage = GetStorage();
  static const List<String> _fallbackHosts = [
    'http://localhost:8080',
    'http://10.33.108.4:8080',
    'http://10.0.2.2:8080',
    'http://127.0.0.1:8080',
  ];

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final String? token = _storage.read(StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('--> ${options.method.toUpperCase()} ${options.uri}');
            if (options.data != null) debugPrint('Body: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('<-- API Notice: ${e.message} (${e.requestOptions.uri})');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<dynamic> _executeWithFallback(Future<Response> Function(String baseUrl) requestFn) async {
    List<String> hostsToTry = [_dio.options.baseUrl];
    for (var host in _fallbackHosts) {
      if (!hostsToTry.contains(host)) hostsToTry.add(host);
    }

    DioException? lastError;
    for (String host in hostsToTry) {
      try {
        final response = await requestFn(host);
        if (_dio.options.baseUrl != host) {
          _dio.options.baseUrl = host;
          debugPrint('Notice: Switched active API baseUrl to $host');
        }
        return response.data;
      } on DioException catch (e) {
        lastError = e;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          debugPrint('Notice: Host $host unreachable (${e.type}). Retrying with next host...');
          continue;
        }
        throw ApiException.fromDioError(e);
      }
    }

    if (lastError != null) {
      throw ApiException.fromDioError(lastError);
    }
    throw ApiException(message: 'All backend host connections timed out.');
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _executeWithFallback((host) {
      final fullUrl = '$host$path';
      return _dio.get(fullUrl, queryParameters: queryParameters);
    });
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return _executeWithFallback((host) {
      final fullUrl = '$host$path';
      return _dio.post(fullUrl, data: data, queryParameters: queryParameters);
    });
  }

  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return _executeWithFallback((host) {
      final fullUrl = '$host$path';
      return _dio.put(fullUrl, data: data, queryParameters: queryParameters);
    });
  }

  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return _executeWithFallback((host) {
      final fullUrl = '$host$path';
      return _dio.delete(fullUrl, data: data, queryParameters: queryParameters);
    });
  }

  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return _executeWithFallback((host) {
      final fullUrl = '$host$path';
      return _dio.patch(fullUrl, data: data, queryParameters: queryParameters);
    });
  }
}
