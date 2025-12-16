import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mobile/Controller/tokenController.dart';

class DioClient {
  final Dio _dio;

  DioClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://fyp-1-izlh.onrender.com', // 👈 no trailing / is fine
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // 🔍 Request/Response logs
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
      ),
    );

    // 🔐 Attach token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (Get.isRegistered<TokenController>()) {
            final tk = Get.find<TokenController>().token.value;
            if (tk.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $tk';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) {
          // print debug
          // ignore: avoid_print
          print('Dio error: ${e.message} (${e.response?.statusCode})');
          handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
