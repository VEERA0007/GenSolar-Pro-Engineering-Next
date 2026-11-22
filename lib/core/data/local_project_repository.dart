import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/solar_project.dart';
import 'project_repository.dart';

class LocalProjectRepository implements ProjectRepository {
  LocalProjectRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'gensolar.projects.v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _operationQueue = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final operation = _operationQueue.then((_) => action());
    // Serialize reads and writes so a refresh cannot observe a half-finished
    // import or race a pending save. An individual failure does not poison
    // the queue, while the submitting caller still receives that failure.
    _operationQueue = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<List<SolarProject>> _readAll() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => SolarProject.fromJson(item as Map<String, Object?>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } on FormatException {
      throw const FormatException('Saved project data is invalid. Export a backup before resetting local data.');
    } on TypeError {
      throw const FormatException('Saved project data has an unsupported format.');
    }
  }

  Future<void> _write(List<SolarProject> projects) async {
    final encoded = jsonEncode(projects.map((project) => project.toJson()).toList());
    await _preferences.setString(_storageKey, encoded);
  }

  @override
  Future<List<SolarProject>> loadAll() => _serialize(() async {
    final projects = await _readAll();
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  });

  @override
  Future<void> save(SolarProject project) => _serialize(() async {
    final projects = await _readAll();
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index == -1) {
      projects.insert(0, project);
    } else {
      projects[index] = project;
    }
    await _write(projects);
  });

  @override
  Future<void> delete(String id) => _serialize(() async {
    final projects = await _readAll();
    projects.removeWhere((item) => item.id == id);
    await _write(projects);
  });

  @override
  Future<String> exportJson() async {
    final projects = await loadAll();
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'projects': projects.map((project) => project.toJson()).toList(),
    });
  }

  @override
  Future<int> importJson(String source) async {
    if (source.length > 25 * 1024 * 1024) {
      throw const FormatException('Backup JSON is larger than the 25 MB safety limit.');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 || decoded['projects'] is! List) {
      throw const FormatException('Unsupported GenSolar backup format.');
    }
    final rawProjects = decoded['projects'] as List<dynamic>;
    if (rawProjects.length > 10000) {
      throw const FormatException('Backup contains more than 10,000 projects.');
    }
    final imported = <SolarProject>[];
    final importedIds = <String>{};
    for (final item in rawProjects) {
      if (item is! Map) {
        throw const FormatException('A project record in this backup is not a JSON object.');
      }
      final project = SolarProject.fromJson(Map<String, Object?>.from(item));
      if (project.id.trim().isEmpty || project.name.trim().isEmpty ||
          !project.targetCapacityKw.isFinite || project.targetCapacityKw < 0) {
        throw const FormatException('A project record contains an invalid ID, name or capacity.');
      }
      if (!importedIds.add(project.id)) {
        throw const FormatException('The backup contains duplicate project IDs.');
      }
      imported.add(project);
    }
    return _serialize(() async {
      final existing = await _readAll();
      final byId = {for (final project in existing) project.id: project};
      for (final project in imported) {
        byId[project.id] = project;
      }
      await _write(byId.values.toList());
      return imported.length;
    });
  }
}
