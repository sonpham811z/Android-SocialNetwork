import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  late Dio _dioAuth; 
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _inMemoryAccessToken;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _failedRequestsQueue = [];

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: Environment.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
    ));

    _dioAuth = Dio(BaseOptions(
      baseUrl: Environment.baseUrl,
      headers: {'Content-Type': 'application/json'},
    ));

    _initTokenFromStorage();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_inMemoryAccessToken != null) {
            final safeToken = _inMemoryAccessToken!.replaceAll(RegExp(r'[^A-Za-z0-9\-\_\.]'), '');
        
            options.headers['Authorization'] = 'Bearer $safeToken';
          }
          return handler.next(options);
        },
        
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;
            
            // 1. Nhốt request bị 401 vào hàng đợi
            final completer = Completer<Response>();
            _failedRequestsQueue.add({
              'options': requestOptions,
              'handler': handler,
            });

            if (!_isRefreshing) {
              _isRefreshing = true;

              try {
                final refreshToken = await _secureStorage.read(key: 'refreshToken');
                if (refreshToken == null || refreshToken.isEmpty) throw Exception("No Refresh Token");

                final response = await _dioAuth.post(
                  '/auth/refresh-token',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200) {
                  final payload = response.data['data'] ?? response.data;
                  final newAccessToken = payload['accessToken'] ?? payload['AccessToken'];
                  final newRefreshToken = payload['refreshToken'] ?? payload['RefreshToken'];

                  // Cập nhật RAM & Storage
                  _inMemoryAccessToken = newAccessToken;
                  await _secureStorage.write(key: 'accessToken', value: newAccessToken);
                  if (newRefreshToken != null) {
                    await _secureStorage.write(key: 'refreshToken', value: newRefreshToken);
                  }

                  // 2. GIẢI CỨU HÀNG ĐỢI (Cực kỳ quan trọng: Dùng try-catch bên trong vòng lặp)
                  for (var queuedRequest in _failedRequestsQueue) {
                    final options = queuedRequest['options'] as RequestOptions;
                    final h = queuedRequest['handler'] as ErrorInterceptorHandler;
                    
                    options.headers['Authorization'] = 'Bearer $_inMemoryAccessToken';
                    
                    try {
                      final retryResponse = await dio.fetch(options);
                      h.resolve(retryResponse); 
                    } catch (retryError) {
                      // Nếu một API trong queue vẫn tạch (như Friend Service sập server) 
                      // thì chỉ báo lỗi cho API đó, không làm hỏng cả hàng đợi.
                      h.reject(retryError is DioException ? retryError : error);
                    }
                  }
                }
              } catch (e) {
                await clearAuth();
                for (var queuedRequest in _failedRequestsQueue) {
                  final h = queuedRequest['handler'] as ErrorInterceptorHandler;
                  h.reject(error); 
                }
              } finally {
                _isRefreshing = false;
                _failedRequestsQueue.clear();
              }
            }
            return; 
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _initTokenFromStorage() async {
    _inMemoryAccessToken = await _secureStorage.read(key: 'accessToken');
  }

  void setToken(String token) {
    _inMemoryAccessToken = token;
  }

  Future<void> clearAuth() async {
    _inMemoryAccessToken = null; 
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }

  Dio get client => dio;
  FlutterSecureStorage get secureStorage => _secureStorage;

  static String buildReadableErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerMessage(e.response?.data);
    if (serverMessage != null && serverMessage.isNotEmpty) return serverMessage;
    if (statusCode == 401) return 'Phiên đăng nhập hết hạn. Vui lòng thử lại.';
    return e.message ?? 'Lỗi kết nối tới máy chủ.';
  }

  static String? _extractServerMessage(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final keys = ['message', 'Message', 'error', 'Error'];
      for (final key in keys) {
        final val = map[key]?.toString().trim();
        if (val != null && val.isNotEmpty) return val;
      }
    }
    return null;
  }
}