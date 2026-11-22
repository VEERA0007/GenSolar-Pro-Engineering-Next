import 'package:flutter_test/flutter_test.dart';
import 'package:gensolar_pro_engineering/core/models/solar_project.dart';

void main() {
  test('SolarProject JSON round trip preserves project fields', () {
    final now = DateTime.utc(2026, 11, 22);
    final project = SolarProject(
      id: 'p-1',
      name: 'Factory rooftop',
      customer: 'Sample customer',
      location: 'Hyderabad',
      targetCapacityKw: 125.5,
      engineeringData: const {'survey': {'latitude': 17.385, 'roofLengthM': 30}},
      createdAt: now,
      updatedAt: now,
    );
    final restored = SolarProject.fromJson(project.toJson());
    expect(restored.id, project.id);
    expect(restored.name, project.name);
    expect(restored.customer, project.customer);
    expect(restored.location, project.location);
    expect(restored.targetCapacityKw, project.targetCapacityKw);
    expect(restored.updatedAt, project.updatedAt);
    expect((restored.engineeringData['survey'] as Map)['roofLengthM'], 30);
  });
}
