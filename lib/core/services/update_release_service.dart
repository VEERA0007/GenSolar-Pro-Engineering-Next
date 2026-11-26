import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GenSolarRelease {
  const GenSolarRelease({
    required this.version,
    required this.buildNumber,
    required this.currentBuildNumber,
    required this.downloadUrl,
    required this.fileName,
    required this.releaseUrl,
  });

  final String version;
  final int buildNumber;
  final int currentBuildNumber;
  final String downloadUrl;
  final String fileName;
  final String releaseUrl;
}

class UpdateCheckResult {
  const UpdateCheckResult({this.release, this.error});
  final GenSolarRelease? release;
  final String? error;
  bool get hasUpdate => release != null;
}

class UpdateReleaseService {
  UpdateReleaseService({Dio? dio}) : _dio = dio ?? Dio();

  static const _latestReleaseUrl =
      'https://api.github.com/repos/VEERA0007/GenSolar-Pro-Engineering-Next/releases/latest';

  final Dio _dio;

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final package = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(package.buildNumber) ?? 0;
      final response = await _dio.get<Map<String, dynamic>>(
        _latestReleaseUrl,
        options: Options(
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final data = response.data;
      if (data == null) return const UpdateCheckResult();

      final tag = data['tag_name'] as String? ?? '';
      final match = RegExp(r'^build-(\d+)$').firstMatch(tag);
      if (match == null) return const UpdateCheckResult();

      final latestBuild = int.parse(match.group(1)!);
      if (latestBuild <= currentBuild) return const UpdateCheckResult();

      final assets = (data['assets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final assetName = _assetNameForPlatform();
      if (assetName == null) return const UpdateCheckResult();

      Map<String, dynamic>? asset;
      for (final candidate in assets) {
        if (candidate['name'] == assetName) {
          asset = candidate;
          break;
        }
      }
      if (asset == null) return const UpdateCheckResult();

      final url = asset['browser_download_url'] as String?;
      if (url == null || url.isEmpty) return const UpdateCheckResult();

      return UpdateCheckResult(
        release: GenSolarRelease(
          version: package.version,
          buildNumber: latestBuild,
          currentBuildNumber: currentBuild,
          downloadUrl: url,
          fileName: assetName,
          releaseUrl: data['html_url'] as String? ?? url,
        ),
      );
    } on DioException catch (error) {
      return UpdateCheckResult(error: error.message ?? 'Update check failed.');
    } catch (error) {
      return UpdateCheckResult(error: error.toString());
    }
  }

  String? _assetNameForPlatform() {
    if (kIsWeb) return 'GenSolar-Pro-Web.zip';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'GenSolar-Pro-Android-debug.apk';
      case TargetPlatform.windows:
        return 'GenSolar-Pro-Windows.zip';
      case TargetPlatform.linux:
        return 'GenSolar-Pro-Linux.zip';
      case TargetPlatform.macOS:
        return 'GenSolar-Pro-macOS.zip';
      case TargetPlatform.iOS:
        return 'GenSolar-Pro-iOS-unsigned.zip';
      case TargetPlatform.fuchsia:
        return null;
    }
  }
}
