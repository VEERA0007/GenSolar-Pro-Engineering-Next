import 'package:flutter_test/flutter_test.dart';
import 'package:gensolar_pro_engineering/core/engineering/solar_calculators.dart';

void main() {
  group('PV sizing', () {
    test('rounds module count upward and calculates installed capacity', () {
      final result = SolarCalculators.calculatePvSizing(
        targetCapacityKw: 10,
        modulePowerW: 550,
        moduleLengthM: 2.278,
        moduleWidthM: 1.134,
        availableRoofAreaM2: 120,
      );
      expect(result.moduleCount, 19);
      expect(result.installedCapacityKw, closeTo(10.45, 0.0001));
      expect(result.moduleAreaM2, greaterThan(0));
      expect(result.planningAreaM2, greaterThan(result.moduleAreaM2));
      expect(result.roofUtilizationPercent, isNotNull);
    });

    test('rejects non-positive capacity', () {
      expect(
        () => SolarCalculators.calculatePvSizing(
          targetCapacityKw: 0,
          modulePowerW: 550,
          moduleLengthM: 2.2,
          moduleWidthM: 1.1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid planning factor', () {
      expect(
        () => SolarCalculators.calculatePvSizing(
          targetCapacityKw: 5,
          modulePowerW: 500,
          moduleLengthM: 2,
          moduleWidthM: 1,
          planningFactor: .5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Battery energy', () {
    test('calculates nominal battery energy with DoD and efficiency', () {
      final result = SolarCalculators.calculateBatteryNominalKwh(
        dailyEnergyKwh: 12,
        autonomyDays: 1.5,
        depthOfDischarge: .8,
        inverterEfficiency: .92,
      );
      expect(result, closeTo(24.4565, .001));
    });

    test('rejects invalid DoD', () {
      expect(
        () => SolarCalculators.calculateBatteryNominalKwh(
          dailyEnergyKwh: 12,
          autonomyDays: 1,
          depthOfDischarge: 1.2,
          inverterEfficiency: .9,
        ),
        throwsArgumentError,
      );
    });
  });

  test('estimates maximum series modules using cold Voc', () {
    final count = SolarCalculators.calculateSeriesModules(
      inverterMaxDcVoltage: 1000,
      moduleVoc: 49.5,
      minimumTemperatureC: 5,
      vocTemperatureCoefficientPerC: .0028,
    );
    expect(count, greaterThan(0));
    expect(count, lessThan(1000 ~/ 49));
  });
}
