import 'package:dio/dio.dart';

class NetworkClient {
  const NetworkClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      url,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
