import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'APNASTAY_API_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator reaches the host computer through this address.
        return 'http://10.0.2.2:8000';
      default:
        // iOS Simulator and desktop builds run on the same computer as FastAPI.
        return 'http://127.0.0.1:8000';
    }
  }

  final Dio _dio;

  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            ),
          );

  Options _options(String? idToken) => Options(
    headers: idToken == null
        ? null
        : <String, String>{'Authorization': 'Bearer $idToken'},
  );

  Future<Response<dynamic>> get(
    String path, {
    String? idToken,
    Map<String, dynamic>? queryParameters,
  }) => _dio.get(
    path,
    queryParameters: queryParameters,
    options: _options(idToken),
  );

  Future<Response<dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? idToken,
  }) => _dio.post(path, data: body, options: _options(idToken));

  Future<Response<dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
    String? idToken,
  }) => _dio.put(path, data: body, options: _options(idToken));

  Future<Response<dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
    String? idToken,
  }) => _dio.patch(path, data: body, options: _options(idToken));

  Future<Response<dynamic>> uploadVideo(
    String path, {
    required List<int> bytes,
    required String filename,
    String category = 'pg_video',
    String? pgId,
    required String idToken,
  }) {
    final extension = filename.split('.').last.toLowerCase();
    final subtype = switch (extension) {
      'mp4' => 'mp4',
      'mov' => 'quicktime',
      'webm' => 'webm',
      'm4v' => 'x-m4v',
      _ => null,
    };
    if (subtype == null) {
      throw ArgumentError('Only MP4, MOV, WebM, and M4V videos are supported.');
    }
    if (bytes.isEmpty) throw ArgumentError('The selected video is empty.');

    final formData = FormData.fromMap({
      'video': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('video', subtype),
      ),
      'category': category,
      if (pgId != null && pgId.isNotEmpty) 'pg_id': pgId,
    });

    return _dio.post(
      path,
      data: formData,
      options: Options(
        headers: <String, String>{'Authorization': 'Bearer $idToken'},
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
  }

  Future<Response<dynamic>> uploadImage(
    String path, {
    required List<int> bytes,
    required String filename,
    required String category,
    String? pgId,
    required String idToken,
  }) {
    final extension = filename.split('.').last.toLowerCase();
    final subtype = switch (extension) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'webp' => 'webp',
      _ => null,
    };
    if (subtype == null) {
      throw ArgumentError('Only JPG, PNG, and WebP images are supported.');
    }

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('image', subtype),
      ),
      'category': category,
      if (pgId != null && pgId.isNotEmpty) 'pg_id': pgId,
    });

    return _dio.post(
      path,
      data: formData,
      options: Options(
        headers: <String, String>{'Authorization': 'Bearer $idToken'},
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 75),
      ),
    );
  }
}
