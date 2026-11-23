import 'package:flutter_test/flutter_test.dart';
import 'package:gensolar_pro_engineering/core/engineering/engineering_workflows.dart';

void main() {
  group('Site survey screening', () {
    test('calculates footprint, sloped surface and setbacks', () {
      final result = SolarCalculators.calculateSurvey(
        latitude: 17.385, longitude: 78.4867, elevationM: 540,
        roofLengthM: 30, roofWidthM: 20, roofTiltDeg: 10,
        edgeSetbackM: .5, walkwayWidthM: 1,
      );
      expect(result.metrics[2].value, '600.00');
      expect(double.parse(result.metrics[3].value), closeTo(609.26, .02));
      expect(result.warnings, isEmpty);
    });

    test('rejects invalid coordinates', () {
      expect(() => SolarCalculators.calculateSurvey(
        latitude: 91, longitude: 0, elevationM: 0, roofLengthM: 10,
        roofWidthM: 10, roofTiltDeg: 0, edgeSetbackM: 0, walkwayWidthM: 0,
      ), throwsArgumentError);
    });
  });

  group('PV layout', () {
    test('selects a feasible rectangular grid and calculates installed capacity', () {
      final result = SolarCalculators.calculateRectangularPvLayout(
        roofLengthM: 30, roofWidthM: 20, modulePowerW: 550,
        moduleLengthM: 2.278, moduleWidthM: 1.134, edgeSetbackM: .5,
        walkwayWidthM: 1, moduleGapM: .03, targetCapacityKw: 10,
      );
      expect(result.moduleCount, greaterThan(0));
      expect(result.columns, greaterThan(0));
      expect(result.rows, greaterThan(0));
      expect(result.moduleCount * 550 / 1000, closeTo(
        double.parse(result.metrics[1].value), .01));
    });

    test('manual exclusions reduce installed module count', () {
      final base = SolarCalculators.calculateRectangularPvLayout(
        roofLengthM: 20, roofWidthM: 12, modulePowerW: 550,
        moduleLengthM: 2.2, moduleWidthM: 1.1, edgeSetbackM: .3,
        walkwayWidthM: .8, moduleGapM: .03, targetCapacityKw: 5,
      );
      final edited = SolarCalculators.calculateRectangularPvLayout(
        roofLengthM: 20, roofWidthM: 12, modulePowerW: 550,
        moduleLengthM: 2.2, moduleWidthM: 1.1, edgeSetbackM: .3,
        walkwayWidthM: .8, moduleGapM: .03, targetCapacityKw: 5,
        excludedCellIndexes: [0, 1, 2],
      );
      expect(edited.moduleCount, base.moduleCount - 3);
    });

    test('rejects roof consumed by setbacks', () {
      expect(() => SolarCalculators.calculateRectangularPvLayout(
        roofLengthM: 2, roofWidthM: 2, modulePowerW: 500,
        moduleLengthM: 2, moduleWidthM: 1, edgeSetbackM: 1,
        walkwayWidthM: 0, moduleGapM: 0, targetCapacityKw: 1,
      ), throwsArgumentError);
    });
  });

  group('Energy yield', () {
    test('calculates annual generation and value from stated assumptions', () {
      final result = SolarCalculators.calculateYield(
        dcCapacityKw: 10, specificYieldKwhPerKwp: 1600,
        performanceRatioPercent: 80, additionalLossPercent: 5,
        tariffInrPerKwh: 8,
      );
      expect(double.parse(result.metrics.first.value), closeTo(12160, .1));
      expect(result.metrics.last.value, '₹97280');
    });
  });

  group('Electrical screening', () {
    test('cold-corrects Voc and checks MPPT and DC cable drop', () {
      final result = SolarCalculators.calculateElectrical(
        moduleVocV: 49.5, vocTempCoefficientPercentPerC: .28,
        minimumTemperatureC: 5, moduleVmpV: 41.5, modulesPerString: 18,
        stringCount: 4, inverterMaxDcVoltageV: 1100, mpptMinVoltageV: 180,
        mpptMaxVoltageV: 1000, inverterAcKw: 10, cableCurrentA: 15,
        cableLengthM: 35, cableAreaMm2: 6, systemVoltageV: 750,
      );
      expect(double.parse(result.metrics[1].value), greaterThan(900));
      expect(result.metrics.last.value, '10.00');
    });

    test('rejects an invalid MPPT window', () {
      expect(() => SolarCalculators.calculateElectrical(
        moduleVocV: 49, vocTempCoefficientPercentPerC: .28,
        minimumTemperatureC: 5, moduleVmpV: 40, modulesPerString: 18,
        stringCount: 4, inverterMaxDcVoltageV: 1100, mpptMinVoltageV: 1000,
        mpptMaxVoltageV: 180, inverterAcKw: 10, cableCurrentA: 15,
        cableLengthM: 35, cableAreaMm2: 6, systemVoltageV: 750,
      ), throwsArgumentError);
    });
  });

  group('Battery and wind', () {
    test('calculates usable, nominal energy and equivalent Ah', () {
      final result = SolarCalculators.calculateBattery(
        criticalLoadKw: 5, autonomyHours: 4, depthOfDischargePercent: 80,
        roundTripEfficiencyPercent: 90, nominalVoltageV: 512,
        inverterContinuousKw: 6,
      );
      expect(double.parse(result.metrics[1].value), closeTo(27.78, .001));
      expect(double.parse(result.metrics[2].value.split(' ').first), closeTo(54.25, .1));
    });

    test('marks wind output as preliminary review', () {
      final result = SolarCalculators.calculateWindScreen(
        designWindSpeedMps: 39, forceCoefficient: 1.5, effectiveAreaM2: 30,
      );
      expect(result.status, contains('ENGINEER REVIEW'));
      expect(result.warnings, isNotEmpty);
    });
  });

  group('BOM and CAD exchange', () {
    test('generates rate-based BOM with rounded inverter count', () {
      final lines = SolarCalculators.calculateBom(
        moduleCount: 19, moduleWidthM: 1.134, modulePowerW: 550,
        inverterSizeKw: 10, dcCableLengthM: 100, acCableLengthM: 40,
        moduleRate: 9000, inverterRate: 95000, railRatePerM: 450,
        clampRate: 35, cableRatePerM: 80, earthingAllowance: 25000,
      );
      expect(lines.first.quantity, 19);
      expect(lines[1].quantity, 2);
      expect(lines.first.amount, 171000);
      expect(lines.fold<double>(0, (sum, line) => sum + line.amount), greaterThan(0));
    });

    test('exports metre-unit DXF entities for roof and PV grid', () {
      final dxf = SolarCalculators.createDxf(
        roofLengthM: 20, roofWidthM: 10, rows: 3, columns: 4,
        panelLengthM: 2, panelWidthM: 1, edgeSetbackM: .5,
        walkwayWidthM: 1, moduleGapM: .05, excludedCells: {0},
      );
      expect(dxf, contains(r'$INSUNITS'));
      expect(dxf, contains('PV_MODULE'));
      expect(dxf, contains('10\n2.5500\n')); // Second row includes the 50 mm module gap.
      expect(dxf, endsWith('0\nEOF\n'));
    });
  });
}
