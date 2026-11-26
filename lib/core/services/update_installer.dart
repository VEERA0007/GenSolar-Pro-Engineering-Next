import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateInstallStatus { launched, openedDownloadPage, unsupported, failed }

class UpdateInstallResult {
  const UpdateInstallResult(this.status, {this.message});
  final UpdateInstallStatus status;
  final String? message;
}

class UpdateInstaller {
  Future<UpdateInstallResult> install({
    required String downloadedPath,
    required String releaseUrl,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final uri = Uri.tryParse(releaseUrl);
        if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return const UpdateInstallResult(
            UpdateInstallStatus.unsupported,
            message: 'Install the signed update through the Apple App Store or TestFlight.',
          );
        }
        return const UpdateInstallResult(
          UpdateInstallStatus.openedDownloadPage,
          message: 'Continue the update through Apple distribution.',
        );
      }

      if (kIsWeb) {
        final uri = Uri.tryParse(releaseUrl);
        if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return const UpdateInstallResult(
            UpdateInstallStatus.failed,
            message: 'Could not open the release download page.',
          );
        }
        return const UpdateInstallResult(
          UpdateInstallStatus.openedDownloadPage,
          message: 'The browser will handle the downloaded web bundle. Refresh after deployment.',
        );
      }

      final result = await OpenFilex.open(
        downloadedPath,
        type: defaultTargetPlatform == TargetPlatform.android
            ? 'application/vnd.android.package-archive'
            : null,
      );
      if (result.type == ResultType.done) {
        return const UpdateInstallResult(UpdateInstallStatus.launched);
      }
      return UpdateInstallResult(
        UpdateInstallStatus.failed,
        message: result.message,
      );
    } catch (error) {
      return UpdateInstallResult(
        UpdateInstallStatus.failed,
        message: error.toString(),
      );
    }
  }
}
