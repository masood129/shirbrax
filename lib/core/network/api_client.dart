import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../storage/local_storage.dart';
import 'api_endpoints.dart';
import 'package:shirbrax/app/routes/app_pages.dart';

/// Dio HTTP client with auth interceptor and error handling
class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);

    return dio;
  }
}

// ─── Auth Interceptor ───────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired — clear auth and redirect to login
      await LocalStorage.clearAuth();
      AppPages.router.go('/login');
    }
    handler.next(err);
  }
}

// ─── Logging Interceptor ────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
}

// ─── Error Interceptor ──────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'اتصال به سرور برقرار نشد. دوباره تلاش کنید.';
        break;
      case DioExceptionType.connectionError:
        message = 'اینترنت شما قطع است.';
        break;
      default:
        final status = err.response?.statusCode;
        if (status == 404) {
          message = 'منبع درخواستی یافت نشد.';
        } else if (status == 500) {
          message = 'خطای سرور. لطفاً بعداً دوباره تلاش کنید.';
        } else {
          message = err.response?.data?['message'] ?? 'خطای ناشناخته.';
        }
    }

    // Show snackbar if GetX overlay is available
    try {
      Get.snackbar(
        'خطا',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      // ignore: avoid_print
      print('[NetworkError] $message');
    }

    handler.next(err);
  }
}
