import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:gensolar_pro_engineering/core/data/local_project_repository.dart';
import 'package:gensolar_pro_engineering/core/models/solar_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalProjectRepository repository;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    repository = LocalProjectRepository();
  });

  SolarProject project(String id, {String name = 'Rooftop project'}) {
    final now = DateTime.utc(2026, 11, 23);
    return SolarProject(
      id: id,
      name: name,
      targetCapacityKw: 10,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('fresh installation loads an empty mutable project list', () async {
    final projects = await repository.loadAll();
    expect(projects, isEmpty);
    expect(() => projects.add(project('p-1')), returnsNormally);
  });

  test('save creates and updates projects without mutating immutable data', () async {
    await repository.save(project('p-1'));
    await repository.save(project('p-2', name: 'Factory'));
    await repository.save(project('p-1', name: 'Updated rooftop'));

    final projects = await repository.loadAll();
    expect(projects, hasLength(2));
    expect(projects.map((item) => item.id), containsAll(['p-1', 'p-2']));
    expect(projects.firstWhere((item) => item.id == 'p-1').name, 'Updated rooftop');
  });

  test('delete removes a project from local storage', () async {
    await repository.save(project('p-1'));
    await repository.delete('p-1');
    expect(await repository.loadAll(), isEmpty);
  });

  test('JSON backup can be exported and restored', () async {
    await repository.save(project('p-1'));
    final backup = await repository.exportJson();

    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    repository = LocalProjectRepository();
    expect(await repository.importJson(backup), 1);
    expect((await repository.loadAll()).single.id, 'p-1');
  });

  test('invalid backup is rejected without changing saved projects', () async {
    await repository.save(project('p-1'));
    expect(() => repository.importJson('{"schemaVersion":99,"projects":[]}'),
        throwsFormatException);
    expect((await repository.loadAll()).single.id, 'p-1');
  });
}
