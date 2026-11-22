import '../models/solar_project.dart';

abstract interface class ProjectRepository {
  Future<List<SolarProject>> loadAll();
  Future<void> save(SolarProject project);
  Future<void> delete(String id);
  Future<String> exportJson();
  Future<int> importJson(String source);
}
