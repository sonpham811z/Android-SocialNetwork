//same feature with axios interceptor
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CookieJar _cookieJar = CookieJar();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30)
      ),
    );

    dio.interceptors.add(CookieManager(_cookieJar));

    //request interceptor - add token to each request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'accessToken'); // get token from secure storage

          if(token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onError: (error, handler) async {
          if(error.response?.statusCode == 401)
          {
            final requestOptions = error.requestOptions;

            if(requestOptions.extra['_retry'] != true) {
              requestOptions.extra['retry'] = true;

              try {
                final refreshResponse = await dio.post(
                  '/auth/refresh-token',
                  options: Options(
                    extra: {'_retry': true},
                  ),
                );

                if (refreshResponse.statusCode == 200)
                {
                  final newAcessToken = refreshResponse.data['data']['accessToken'];

                  //save new token at keyStore
                  await _secureStorage.write(key: 'accessToken', value: newAcessToken);

                  requestOptions.headers['Authorization'] = 'Bearer $newAcessToken';

                  final response = await dio.fetch(requestOptions);

                  return handler.resolve(response);
                }

              } catch (refreshError) {
                await _secureStorage.delete(key: 'accessToken');

                return handler.reject(error);
              }
            }
          }
          
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => dio;

  // secure storage instance
  FlutterSecureStorage get secureStorage => _secureStorage;

  //Clear auth data

  Future<void> clearAuth() async{
    await _secureStorage.delete(key: 'accessToken');
    _cookieJar.deleteAll();
  }
}