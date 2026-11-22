import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/section_heading.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(projectRepositoryProvider).exportJson();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Project backup JSON'),
          content: SizedBox(
            width: 650,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Copy this backup and store it in a safe location. It contains the project records currently stored on this device.'),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup copied to clipboard.')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy backup'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $error')));
    }
  }

  Future<void> _saveBackupFile(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(projectRepositoryProvider).exportJson();
      await FileSaver.instance.saveFile(
        name: 'gensolar-project-backup-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}',
        bytes: Uint8List.fromList(utf8.encode(json)),
        fileExtension: 'json',
        mimeType: MimeType.json,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project backup file saved.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup file export failed: $error')));
      }
    }
  }

  Future<void> _importBackupFile(BuildContext context, WidgetRef ref) async {
    try {
      // file_picker 13 exposes a platform-neutral top-level picker. Reading
      // through PlatformFile also works on web where filesystem paths are not available.
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final length = file.lengthSync() ?? await file.length();
      if (length != null && length > 25 * 1024 * 1024) {
        throw const FormatException('Backup file is larger than the 25 MB safety limit.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 25 * 1024 * 1024) {
        throw const FormatException('Backup file is larger than the 25 MB safety limit.');
      }
      final source = utf8.decode(bytes, allowMalformed: false);
      final count = await ref.read(projectRepositoryProvider).importJson(source);
      ref.invalidate(projectsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored $count project record(s) from ${file.name}.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup file restore failed: $error')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    try {
      final source = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore project backup'),
          content: SizedBox(
            width: 650,
            child: TextField(
              controller: controller,
              minLines: 8,
              maxLines: 14,
              decoration: const InputDecoration(labelText: 'Paste GenSolar backup JSON', alignLabelWithHint: true),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Restore')),
          ],
        ),
      );
      if (source == null || source.trim().isEmpty) return;
      final count = await ref.read(projectRepositoryProvider).importJson(source);
      ref.invalidate(projectsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restored $count project record(s).')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeading(title: 'Application settings'),
              const SizedBox(height: 16),
              Card(child: Column(children: [
                const ListTile(
                  leading: Icon(Icons.offline_bolt_outlined),
                  title: Text('Offline-first storage'),
                  subtitle: Text('Project records are saved locally on this device.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Export project backup'),
                  subtitle: const Text('Create a JSON backup of local project records.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Save backup as JSON file'),
                  subtitle: const Text('Download a portable backup containing all projects on this device.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _saveBackupFile(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Restore from JSON file'),
                  subtitle: const Text('Select a GenSolar project backup from this device.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importBackupFile(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore project backup'),
                  subtitle: const Text('Merge records from a GenSolar JSON backup.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importBackup(context, ref),
                ),
              ])),
              const SizedBox(height: 16),
              Card(child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Technology', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const _TechnologyRow(label: 'Cross-platform UI', value: 'Flutter 3.50.0'),
                  const _TechnologyRow(label: 'Language', value: 'Dart 3.14.0'),
                  const _TechnologyRow(label: 'State management', value: 'Riverpod 3'),
                  const _TechnologyRow(label: 'Local project store', value: 'SharedPreferencesAsync (starter)'),
                  const _TechnologyRow(label: 'Application version', value: '1.0.0 · fresh codebase'),
                ]),
              )),
              const SizedBox(height: 12),
              Text('Before production deployment, replace preference-based project storage with a transactional database for large engineering projects, add encryption and account synchronization, and complete security and engineering verification.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );
}

class _TechnologyRow extends StatelessWidget {
  const _TechnologyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );
}
