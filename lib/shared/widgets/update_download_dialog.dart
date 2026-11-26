import 'package:material_ui/material_ui.dart';

import '../../core/services/update_download_controller.dart';

/// Screenshot-style update download dialog with live byte progress and
/// a Cancel action that cancels the underlying HTTP request.
class UpdateDownloadDialog extends StatefulWidget {
  const UpdateDownloadDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.fileName,
    this.onDownloaded,
  });

  final String currentVersion;
  final String newVersion;
  final String downloadUrl;
  final String releaseUrl;
  final String fileName;
  final ValueChanged<String>? onDownloaded;

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  late final UpdateDownloadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UpdateDownloadController();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final result = await _controller.download(
      url: widget.downloadUrl,
      fileName: widget.fileName,
    );
    if (!mounted || result == null) return;
    widget.onDownloaded?.call(result);
  }

  @override
  void dispose() {
    _controller.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.status;
          final active = state == UpdateDownloadStatus.downloading ||
              state == UpdateDownloadStatus.cancelling;
          final progress = _controller.progress;
          final percent = progress == null
              ? null
              : (progress * 100).round();
          final headline = switch (state) {
            UpdateDownloadStatus.downloading => 'Downloading update...',
            UpdateDownloadStatus.cancelling => 'Cancelling download...',
            UpdateDownloadStatus.completed => 'Download complete',
            UpdateDownloadStatus.cancelled => 'Download cancelled',
            UpdateDownloadStatus.failed => 'Download failed',
            UpdateDownloadStatus.idle => 'Preparing download...',
          };

          return Dialog(
            backgroundColor: const Color(0xFF1D4140),
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(0xFF075E5D),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.system_update_alt_rounded,
                            color: Color(0xFF22D6D0),
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'A new GenSolar version is ready',
                                style: TextStyle(
                                  color: Color(0xFFB9CECB),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _VersionPill(label: 'Current', value: 'v${widget.currentVersion}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF22D6D0),
                            size: 30,
                          ),
                        ),
                        _VersionPill(
                          label: 'New',
                          value: 'v${widget.newVersion}',
                          highlighted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_download_rounded,
                          color: Color(0xFF22D6D0),
                          size: 23,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            headline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFF365B58),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF20D4CE),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_controller.receivedLabel} / ${_controller.totalLabel}',
                          style: const TextStyle(
                            color: Color(0xFFB9CECB),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          percent == null ? '--' : '$percent%',
                          style: const TextStyle(
                            color: Color(0xFF22D6D0),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (state == UpdateDownloadStatus.failed) ...[
                      const SizedBox(height: 12),
                      Text(
                        _controller.errorMessage ?? 'Please try again.',
                        style: const TextStyle(color: Color(0xFFFFB4AB)),
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: active
                            ? _controller.cancel
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD4E3E0),
                          side: const BorderSide(color: Color(0xFF456966)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          state == UpdateDownloadStatus.cancelling
                              ? 'Cancelling...'
                              : active
                                  ? 'Cancel'
                                  : state == UpdateDownloadStatus.completed
                                      ? 'Done'
                                      : 'Close',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9CECB),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: highlighted
                  ? const Color(0xFF075E5D)
                  : const Color(0xFF294846),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                value,
                style: TextStyle(
                  color: highlighted
                      ? const Color(0xFF22D6D0)
                      : const Color(0xFFE0EBE8),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
}
