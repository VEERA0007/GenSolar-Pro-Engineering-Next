import 'dart:math' as math;

class PvSizingResult {
  const PvSizingResult({
    required this.moduleCount,
    required this.installedCapacityKw,
    required this.moduleAreaM2,
    required this.planningAreaM2,
    required this.roofUtilizationPercent,
  });

  final int moduleCount;
  final double installedCapacityKw;
  final double moduleAreaM2;
  final double planningAreaM2;
  final double? roofUtilizationPercent;
}

class SolarCalculators {
  static PvSizingResult calculatePvSizing({
    required double targetCapacityKw,
    required double modulePowerW,
    required double moduleLengthM,
    required double moduleWidthM,
    double? availableRoofAreaM2,
    double planningFactor = 1.20,
  }) {
    if (!targetCapacityKw.isFinite || targetCapacityKw <= 0) {
      throw ArgumentError.value(targetCapacityKw, 'targetCapacityKw', 'Must be positive.');
    }
    if (!modulePowerW.isFinite || modulePowerW <= 0) {
      throw ArgumentError.value(modulePowerW, 'modulePowerW', 'Must be positive.');
    }
    if (!moduleLengthM.isFinite || moduleLengthM <= 0 ||
        !moduleWidthM.isFinite || moduleWidthM <= 0) {
      throw ArgumentError('Module dimensions must be positive finite values.');
    }
    if (!planningFactor.isFinite || planningFactor < 1 || planningFactor > 3) {
      throw ArgumentError.value(planningFactor, 'planningFactor', 'Use a factor from 1.0 to 3.0.');
    }
    if (availableRoofAreaM2 != null &&
        (!availableRoofAreaM2.isFinite || availableRoofAreaM2 <= 0)) {
      throw ArgumentError.value(availableRoofAreaM2, 'availableRoofAreaM2', 'Must be positive when supplied.');
    }

    final count = (targetCapacityKw * 1000 / modulePowerW).ceil();
    final area = count * moduleLengthM * moduleWidthM;
    final planningArea = area * planningFactor;
    return PvSizingResult(
      moduleCount: count,
      installedCapacityKw: count * modulePowerW / 1000,
      moduleAreaM2: area,
      planningAreaM2: planningArea,
      roofUtilizationPercent: availableRoofAreaM2 == null
          ? null
          : planningArea / availableRoofAreaM2 * 100,
    );
  }

  static double calculateBatteryNominalKwh({
    required double dailyEnergyKwh,
    required double autonomyDays,
    required double depthOfDischarge,
    required double inverterEfficiency,
  }) {
    if (!dailyEnergyKwh.isFinite || !autonomyDays.isFinite ||
        !depthOfDischarge.isFinite || !inverterEfficiency.isFinite ||
        dailyEnergyKwh <= 0 || autonomyDays <= 0 ||
        depthOfDischarge <= 0 || depthOfDischarge > 1 ||
        inverterEfficiency <= 0 || inverterEfficiency > 1) {
      throw ArgumentError('Energy and autonomy must be positive; DoD and efficiency must be within (0, 1].');
    }
    return dailyEnergyKwh * autonomyDays /
        (depthOfDischarge * inverterEfficiency);
  }

  static int calculateSeriesModules({
    required double inverterMaxDcVoltage,
    required double moduleVoc,
    required double minimumTemperatureC,
    required double vocTemperatureCoefficientPerC,
  }) {
    if (!inverterMaxDcVoltage.isFinite || !moduleVoc.isFinite ||
        !minimumTemperatureC.isFinite ||
        !vocTemperatureCoefficientPerC.isFinite ||
        inverterMaxDcVoltage <= 0 || moduleVoc <= 0 ||
        vocTemperatureCoefficientPerC < 0) {
      throw ArgumentError('Invalid string-sizing inputs.');
    }
    final coldVoc = moduleVoc *
        (1 + vocTemperatureCoefficientPerC * (25 - minimumTemperatureC));
    if (coldVoc <= 0 || !coldVoc.isFinite) {
      throw ArgumentError('Calculated cold module Voc is invalid.');
    }
    return math.max(1, (inverterMaxDcVoltage / coldVoc).floor());
  }
}
