import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiInterceptor extends Interceptor {
  final _secureStorage = const FlutterSecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers[ApiConstants.authorization] =
          '${ApiConstants.bearer} $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken =
          await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = Dio(
            BaseOptions(baseUrl: ApiConstants.baseUrl),
          );
          final response = await dio.post(
            ApiEndpoints.refreshToken,
            data: {'refresh_token': refreshToken},
          );
          final newToken = response.data['access_token'];
          await _secureStorage.write(key: 'access_token', value: newToken);

          err.requestOptions.headers[ApiConstants.authorization] =
              '${ApiConstants.bearer} $newToken';
          final retryResponse = await dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          await _secureStorage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}
