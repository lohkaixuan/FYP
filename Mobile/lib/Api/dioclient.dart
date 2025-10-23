import 'package:dio/dio.dart';
import 'package:mobile/Api/tokenController.dart'; // ← TokenController

class DioClient {
  final Dio _dio;

  DioClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://fyp-1-izlh.onrender.com/api/',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenController.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Debug
          // ignore: avoid_print
          print("error dio client $e");

          // 这里可选：根据 401 触发登出或刷新
          // if (e.response?.statusCode == 401) {
          //   await TokenController.removeToken();
          //   // Get.offAllNamed('/login'); // 如果你想自动退回登录
          // }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
