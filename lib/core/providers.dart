import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local_project_repository.dart';
import 'data/project_repository.dart';
import 'models/solar_project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => LocalProjectRepository(),
);

final projectsProvider = FutureProvider<List<SolarProject>>((ref) {
  return ref.watch(projectRepositoryProvider).loadAll();
});

class AppNavigationController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index.clamp(0, 5).toInt();
}

class ActiveProjectController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

class ActiveWorkspaceTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index.clamp(0, 9).toInt();
}

final appNavigationIndexProvider =
    NotifierProvider<AppNavigationController, int>(AppNavigationController.new);
final activeProjectIdProvider =
    NotifierProvider<ActiveProjectController, String?>(ActiveProjectController.new);
final activeWorkspaceTabProvider =
    NotifierProvider<ActiveWorkspaceTabController, int>(ActiveWorkspaceTabController.new);

final activeProjectProvider = Provider<AsyncValue<SolarProject?>>((ref) {
  final projects = ref.watch(projectsProvider);
  final selectedId = ref.watch(activeProjectIdProvider);
  return projects.whenData((items) {
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.id == selectedId) return item;
    }
    return items.first;
  });
});

/// Flags an existing section as stale without deleting its previous values.
Map<String, Object?> markSectionReview(
  Map<String, Object?> current,
  String sectionKey, {
  required String reason,
}) {
  final next = Map<String, Object?>.from(current);
  final raw = next[sectionKey];
  if (raw is Map && raw.isNotEmpty) {
    final section = Map<String, Object?>.from(raw);
    section['needsReview'] = true;
    section['reviewReason'] = reason;
    next[sectionKey] = section;
  }
  return next;
}

/// Marks downstream design sections for review when an upstream input changes.
/// The source data is retained; stale results are never silently deleted.
Map<String, Object?> markDownstreamReview(
  Map<String, Object?> current,
  String changedSection,
) {
  const dependencies = <String, List<String>>{
    'survey': ['pv', 'yield', 'electrical', 'structural', 'bom', 'cad', 'report'],
    'pv': ['yield', 'electrical', 'bom', 'cad', 'report'],
    'yield': ['report'],
    'electrical': ['bom', 'report'],
    'battery': ['bom', 'report'],
    'structural': ['bom', 'report'],
    'bom': ['procurement', 'delivery', 'report'],
    'procurement': ['delivery', 'report'],
    'delivery': ['report'],
    'cad': ['report'],
  };
  var next = Map<String, Object?>.from(current);
  for (final key in dependencies[changedSection] ?? const <String>[]) {
    next = markSectionReview(
      next,
      key,
      reason: '$changedSection inputs changed after this section was last saved.',
    );
  }
  return next;
}

/// Derives the visible project lifecycle status from saved workflow evidence.
/// This is an operational status only, not an engineering approval.
String deriveProjectStatus(Map<String, Object?> data) {
  if (data.isEmpty) return 'Draft';
  const requiredSections = ['survey', 'pv', 'yield', 'electrical', 'structural', 'bom', 'procurement', 'delivery', 'cad', 'report'];
  final ready = requiredSections.every((key) {
    final value = data[key];
    return value is Map && value.isNotEmpty && value['needsReview'] != true;
  });
  if (ready) return 'Engineering ready';
  return 'In progress';
}
