import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum UpdateDownloadStatus {
  idle,
  downloading,
  cancelling,
  completed,
  cancelled,
  failed,
}

class UpdateDownloadController extends ChangeNotifier {
  UpdateDownloadController({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  CancelToken? _cancelToken;

  UpdateDownloadStatus status = UpdateDownloadStatus.idle;
  int receivedBytes = 0;
  int totalBytes = 0;
  String? downloadedPath;
  String? errorMessage;

  double? get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;

  String get receivedLabel => _formatBytes(receivedBytes);
  String get totalLabel =>
      totalBytes > 0 ? _formatBytes(totalBytes) : 'Size unknown';

  Future<String?> download({
    required String url,
    required String fileName,
  }) async {
    if (status == UpdateDownloadStatus.downloading ||
        status == UpdateDownloadStatus.cancelling) {
      throw StateError('An update download is already running.');
    }

    final safeFileName = fileName
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safeFileName.isEmpty || safeFileName == '.' || safeFileName == '..') {
      throw ArgumentError.value(fileName, 'fileName', 'Invalid file name.');
    }

    receivedBytes = 0;
    totalBytes = 0;
    downloadedPath = null;
    errorMessage = null;
    status = UpdateDownloadStatus.downloading;
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      // Browsers handle the final save location. Native platforms store the
      // package in app support storage until the platform installer opens it.
      final destination = kIsWeb
          ? safeFileName
          : path.join(
              (await getApplicationSupportDirectory()).path,
              safeFileName,
            );

      await _dio.download(
        url,
        destination,
        cancelToken: _cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          receivedBytes = received;
          totalBytes = total;
          notifyListeners();
        },
      );

      downloadedPath = destination;
      status = UpdateDownloadStatus.completed;
      notifyListeners();
      return destination;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        status = UpdateDownloadStatus.cancelled;
      } else {
        status = UpdateDownloadStatus.failed;
        errorMessage = error.message ?? 'The update download failed.';
      }
      notifyListeners();
      return null;
    } catch (error) {
      status = UpdateDownloadStatus.failed;
      errorMessage = error.toString();
      notifyListeners();
      return null;
    } finally {
      _cancelToken = null;
    }
  }

  void cancel() {
    if (status != UpdateDownloadStatus.downloading) return;
    status = UpdateDownloadStatus.cancelling;
    notifyListeners();
    _cancelToken?.cancel('Update download cancelled by the user.');
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
