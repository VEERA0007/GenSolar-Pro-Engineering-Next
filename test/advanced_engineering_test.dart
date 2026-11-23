import 'package:flutter_test/flutter_test.dart';
import 'package:gensolar_pro_engineering/core/engineering/advanced_engineering.dart';

void main() {
  group('Advanced EPC engineering calculations', () {
    test('monthly energy profile returns twelve months and annual sum', () {
      final result = AdvancedEngineering.solarMonthlyYield(
        dcKwp: 10,
        monthlyPoaKwhM2Day: List<double>.filled(12, 5),
        performanceRatioPercent: 80,
        additionalLossPercent: 0,
      );
      expect(result.metrics.keys.where((key) => key.startsWith('Month ')).length, 12);
      expect(result.metrics['Annual energy']!.value, closeTo(14600, 1));
    });

    test('three phase cable drop uses phase factor and warns at entered threshold', () {
      final result = AdvancedEngineering.acCableDrop(
        currentA: 100, lengthM: 250, voltageV: 415, powerFactor: .9,
        resistanceOhmPerKm: .4, reactanceOhmPerKm: .08,
        threePhase: true, projectLimitPercent: .5,
      );
      expect(result.metrics['Voltage drop']!.value, greaterThan(0));
      expect(result.warnings, isNotEmpty);
    });

    test('transformer selector moves up to next available rating', () {
      final result = AdvancedEngineering.transformerSizing(
        maximumDemandKw: 100, powerFactor: 1, loadingLimitPercent: 80, marginPercent: 0,
      );
      expect(result.metrics['Next screening size']!.value, 160);
    });

    test('wind basis applies all entered factors', () {
      final result = AdvancedEngineering.windBasis(
        basicWindSpeedMps: 40, k1: 1, k2: 1.1, k3: 1, k4: 1,
        forceCoefficient: 1, effectiveAreaM2: 10,
      );
      expect(result.metrics['Design speed from entered factors']!.value, 44);
      expect(result.metrics['Reference velocity pressure']!.value, closeTo(1161.6, .01));
      expect(result.warnings, isNotEmpty);
    });

    test('rail beam computes stress and deflection', () {
      final result = AdvancedEngineering.railBeam(
        loadNPerM: 1000, spanM: 1.5, elasticModulusMpa: 69000,
        inertiaMm4: 500000, sectionModulusMm3: 12000,
        allowableStressMpa: 150, deflectionRatio: 180,
      );
      expect(result.metrics['Maximum moment']!.value, closeTo(.28125, .00001));
      expect(result.metrics['Bending stress']!.value, greaterThan(0));
    });

    test('foundation warns when minimum bearing pressure is negative', () {
      final result = AdvancedEngineering.footingBearing(
        verticalLoadKn: 100, momentXKnM: 50, momentYKnM: 0,
        lengthM: 1, widthM: 1, depthM: .5, safeBearingKpa: 150,
      );
      expect(result.metrics['Minimum pressure']!.value, lessThan(0));
      expect(result.warnings.any((warning) => warning.contains('uplift')), isTrue);
    });

    test('earthing ideal parallel estimate reduces with rod count', () {
      final one = AdvancedEngineering.earthingRod(soilResistivityOhmM: 100, rodLengthM: 3, rodDiameterMm: 16, rodCount: 1);
      final four = AdvancedEngineering.earthingRod(soilResistivityOhmM: 100, rodLengthM: 3, rodDiameterMm: 16, rodCount: 4);
      expect(four.metrics['Ideal parallel estimate']!.value, closeTo(one.metrics['Single rod estimate']!.value / 4, .0001));
    });

    test('solar pump energy increases with head', () {
      final low = AdvancedEngineering.solarPump(dailyVolumeM3: 20, totalDynamicHeadM: 10, peakSunHours: 5, pumpEfficiencyPercent: 50, arrayDeratePercent: 80);
      final high = AdvancedEngineering.solarPump(dailyVolumeM3: 20, totalDynamicHeadM: 20, peakSunHours: 5, pumpEfficiencyPercent: 50, arrayDeratePercent: 80);
      expect(high.metrics['PV array estimate']!.value, closeTo(low.metrics['PV array estimate']!.value * 2, .00001));
    });

    test('financial model produces NPV and payback outputs', () {
      final result = AdvancedEngineering.financial(
        annualGenerationKwh: 100000, tariffInrKwh: 8, projectCostInr: 3000000,
        omPercent: 1, degradationPercent: .5, tariffEscalationPercent: 2,
        discountRatePercent: 10, years: 25,
      );
      expect(result.metrics['NPV']!.value.isFinite, isTrue);
      expect(result.metrics['Discounted LCOE proxy']!.value, greaterThan(0));
    });

    test('invalid PF relationship is rejected', () {
      expect(() => AdvancedEngineering.powerFactorCorrection(activePowerKw: 100, existingPf: .95, targetPf: .9), throwsArgumentError);
    });

    test('results serialize formula, input and engine version', () {
      final result = AdvancedEngineering.cableTrayFill(cableCount: 10, cableOdMm: 20, trayWidthMm: 300, trayHeightMm: 75, fillLimitPercent: 40);
      final json = result.toJson();
      expect(json['engineVersion'], '1.1.0');
      expect(json['formula'], isNotEmpty);
      expect(json['inputs'], isA<Map<String, Object?>>());
    });

    test('PV protection screen catches fuse over entered limits', () {
      final result = AdvancedEngineering.pvProtectionScreen(
        moduleIscA: 14, parallelStrings: 4, designCurrentFactor: 1.25,
        selectedFuseRatingA: 80, moduleMaximumSeriesFuseA: 30, cableAllowableCurrentA: 40,
      );
      expect(result.metrics['Design current basis']!.value, 70);
      expect(result.warnings, isNotEmpty);
    });

    test('cable ampacity applies all derating factors', () {
      final result = AdvancedEngineering.cableAmpacityDerating(
        designCurrentA: 100, baseAmpacityA: 200, ambientFactor: .9,
        groupingFactor: .8, installationFactor: .95,
      );
      expect(result.metrics['Effective ampacity']!.value, closeTo(136.8, .001));
      expect(result.warnings, isEmpty);
    });

    test('battery C-rate is power divided by nominal energy', () {
      final result = AdvancedEngineering.batteryCRate(
        nominalEnergyKwh: 100, chargePowerKw: 50, dischargePowerKw: 100,
        dcVoltageV: 500, maximumChargeC: .5, maximumDischargeC: 1,
      );
      expect(result.metrics['Charge C-rate']!.value, .5);
      expect(result.metrics['Discharge current estimate']!.value, 200);
    });

    test('transformer fault current increases with lower impedance', () {
      final lowZ = AdvancedEngineering.transformerFaultCurrent(transformerKva: 500, secondaryVoltageV: 415, impedancePercent: 4);
      final highZ = AdvancedEngineering.transformerFaultCurrent(transformerKva: 500, secondaryVoltageV: 415, impedancePercent: 8);
      expect(lowZ.metrics['Approximate terminal fault current']!.value, greaterThan(highZ.metrics['Approximate terminal fault current']!.value));
    });

    test('rooftop loading scales with equipment mass and area', () {
      final result = AdvancedEngineering.rooftopLoadScreen(
        moduleCount: 100, moduleMassKg: 25, mountingMassPerModuleKg: 5,
        effectiveAreaM2: 300, enteredAllowableLoadKpa: 1.5,
      );
      expect(result.metrics['PV + mounting mass']!.value, 3000);
      expect(result.metrics['Average distributed load']!.value, closeTo(.0980665, .000001));
    });

    test('concrete and reinforcement take-off calculate measurable quantities', () {
      final result = AdvancedEngineering.concreteAndRebarTakeoff(
        lengthM: 2, widthM: 1.5, depthM: .5, concreteWastePercent: 5,
        reinforcementKgPerM3: 100,
      );
      expect(result.metrics['Net concrete']!.value, 1.5);
      expect(result.metrics['Concrete order quantity']!.value, 1.575);
      expect(result.metrics['Reinforcement estimate']!.value, 150);
    });
  });
}
