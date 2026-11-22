import 'dart:math' as math;

class EngineeringMetric {
  const EngineeringMetric(this.label, this.value, {this.unit = ''});
  final String label;
  final String value;
  final String unit;
}

class EngineeringResult {
  const EngineeringResult({
    required this.title,
    required this.status,
    required this.metrics,
    this.notes = const [],
    this.warnings = const [],
    this.columns = 0,
    this.rows = 0,
    this.moduleCount = 0,
    this.panelLengthM = 0,
    this.panelWidthM = 0,
  });

  final String title;
  final String status;
  final List<EngineeringMetric> metrics;
  final List<String> notes;
  final List<String> warnings;
  final int columns;
  final int rows;
  final int moduleCount;
  final double panelLengthM;
  final double panelWidthM;
}

class BomLine {
  const BomLine({required this.name, required this.quantity, required this.unit,
    required this.rate, required this.amount, this.basis = ''});
  final String name;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;
  final String basis;
}

class SolarCalculators {
  static const double copperResistivityOhmMm2PerM = 0.0175;

  static void _positive(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, name, 'Must be a finite value greater than zero.');
    }
  }

  static double _bounded(double value, String name, double min, double max) {
    if (!value.isFinite || value < min || value > max) {
      throw ArgumentError.value(value, name, 'Must be between $min and $max.');
    }
    return value;
  }

  static EngineeringResult calculateSurvey({
    required double latitude,
    required double longitude,
    required double elevationM,
    required double roofLengthM,
    required double roofWidthM,
    required double roofTiltDeg,
    required double edgeSetbackM,
    required double walkwayWidthM,
  }) {
    _bounded(latitude, 'latitude', -90, 90);
    _bounded(longitude, 'longitude', -180, 180);
    if (!elevationM.isFinite) throw ArgumentError.value(elevationM, 'elevationM', 'Must be finite.');
    _positive(roofLengthM, 'roofLengthM');
    _positive(roofWidthM, 'roofWidthM');
    _bounded(roofTiltDeg, 'roofTiltDeg', 0, 60);
    if (edgeSetbackM < 0 || walkwayWidthM < 0 || !edgeSetbackM.isFinite || !walkwayWidthM.isFinite) {
      throw ArgumentError('Setbacks and walkway width cannot be negative.');
    }
    final planArea = roofLengthM * roofWidthM;
    final slopedArea = planArea / math.cos(roofTiltDeg * math.pi / 180);
    final usableLength = roofLengthM - 2 * edgeSetbackM;
    final usableWidth = roofWidthM - 2 * edgeSetbackM - walkwayWidthM;
    final warnings = <String>[];
    if (usableLength <= 0 || usableWidth <= 0) warnings.add('Setbacks and walkway consume the entire roof footprint.');
    if (elevationM < -500 || elevationM > 9000) warnings.add('Elevation is outside the normal project-entry range; verify source and datum.');
    return EngineeringResult(
      title: 'Site and roof survey', status: warnings.isEmpty ? 'INPUTS RECORDED' : 'REVIEW REQUIRED',
      metrics: [
        EngineeringMetric('Coordinates', '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'),
        EngineeringMetric('Elevation', elevationM.toStringAsFixed(1), unit: 'm'),
        EngineeringMetric('Plan footprint', planArea.toStringAsFixed(2), unit: 'm²'),
        EngineeringMetric('Slope surface estimate', slopedArea.toStringAsFixed(2), unit: 'm²'),
        EngineeringMetric('Preliminary usable footprint', math.max(0, usableLength) * math.max(0, usableWidth) > 0 ? (math.max(0, usableLength) * math.max(0, usableWidth)).toStringAsFixed(2) : '0.00', unit: 'm²'),
      ],
      notes: const ['Coordinate and dimension entry only. Verify the survey with calibrated instruments and record the roof-zone boundary, obstructions, access paths and structural condition.'],
      warnings: warnings,
    );
  }

  static EngineeringResult calculateRectangularPvLayout({
    required double roofLengthM,
    required double roofWidthM,
    required double modulePowerW,
    required double moduleLengthM,
    required double moduleWidthM,
    required double edgeSetbackM,
    required double walkwayWidthM,
    required double moduleGapM,
    required double targetCapacityKw,
    List<int> excludedCellIndexes = const [],
  }) {
    _positive(roofLengthM, 'roofLengthM');
    _positive(roofWidthM, 'roofWidthM');
    _positive(modulePowerW, 'modulePowerW');
    _positive(moduleLengthM, 'moduleLengthM');
    _positive(moduleWidthM, 'moduleWidthM');
    _positive(targetCapacityKw, 'targetCapacityKw');
    if (!edgeSetbackM.isFinite || !walkwayWidthM.isFinite || !moduleGapM.isFinite || edgeSetbackM < 0 || walkwayWidthM < 0 || moduleGapM < 0) throw ArgumentError('Setbacks, walkway and module gaps must be finite and cannot be negative.');
    if (edgeSetbackM * 2 >= roofLengthM || edgeSetbackM * 2 + walkwayWidthM >= roofWidthM) {
      throw ArgumentError('The selected setbacks and walkway leave no usable roof area.');
    }
    final freeL = roofLengthM - edgeSetbackM * 2;
    final freeW = roofWidthM - edgeSetbackM * 2 - walkwayWidthM;
    final portrait = _grid(freeL, freeW, moduleLengthM, moduleWidthM, moduleGapM);
    final landscape = _grid(freeL, freeW, moduleWidthM, moduleLengthM, moduleGapM);
    final selected = landscape.$3 > portrait.$3 ? landscape : portrait;
    final allCells = selected.$1 * selected.$2;
    final exclusions = excludedCellIndexes.where((i) => i >= 0 && i < allCells).toSet().length;
    final count = math.max(0, allCells - exclusions).toInt();
    final kw = count * modulePowerW / 1000;
    final moduleArea = count * moduleLengthM * moduleWidthM;
    final roofArea = roofLengthM * roofWidthM;
    final warnings = <String>[];
    if (kw < targetCapacityKw) warnings.add('This rectangular grid does not meet the target DC capacity. Consider another roof zone or a different module arrangement.');
    if (count == 0) warnings.add('No modules fit with the current dimensions and clearances.');
    if (exclusions > 0) warnings.add('$exclusions potential module positions have been manually excluded.');
    return EngineeringResult(
      title: 'PV layout estimate', status: warnings.isEmpty ? 'LAYOUT ESTIMATE' : 'REVIEW LAYOUT',
      columns: selected.$2, rows: selected.$1, moduleCount: count,
      panelLengthM: landscape.$3 > portrait.$3 ? moduleWidthM : moduleLengthM,
      panelWidthM: landscape.$3 > portrait.$3 ? moduleLengthM : moduleWidthM,
      metrics: [
        EngineeringMetric('Modules placed', '$count', unit: 'modules'),
        EngineeringMetric('Installed DC capacity', kw.toStringAsFixed(2), unit: 'kWp'),
        EngineeringMetric('Grid', '${selected.$1} rows × ${selected.$2} columns'),
        EngineeringMetric('Panel surface area', moduleArea.toStringAsFixed(2), unit: 'm²'),
        EngineeringMetric('Panel / gross roof ratio', roofArea == 0 ? '0.0' : '${(moduleArea / roofArea * 100).toStringAsFixed(1)}', unit: '%'),
        EngineeringMetric('Available rectangular footprint', (freeL * freeW).toStringAsFixed(2), unit: 'm²'),
      ],
      notes: [landscape.$3 > portrait.$3 ? 'Landscape orientation fits more panels in this rectangular screening grid.' : 'Portrait orientation fits at least as many panels in this rectangular screening grid.', 'The result is a geometric screening estimate, not a fire-code, wind, structural or authority-approved layout.'],
      warnings: warnings,
    );
  }

  static (int, int, int) _grid(double length, double width, double panelLength, double panelWidth, double gap) {
    final rows = ((length + gap) / (panelLength + gap)).floor();
    final columns = ((width + gap) / (panelWidth + gap)).floor();
    final safeRows = rows < 0 ? 0 : rows;
    final safeColumns = columns < 0 ? 0 : columns;
    return (safeRows, safeColumns, safeRows * safeColumns);
  }

  static EngineeringResult calculateYield({
    required double dcCapacityKw,
    required double specificYieldKwhPerKwp,
    required double performanceRatioPercent,
    required double additionalLossPercent,
    required double tariffInrPerKwh,
  }) {
    _positive(dcCapacityKw, 'dcCapacityKw');
    _positive(specificYieldKwhPerKwp, 'specificYieldKwhPerKwp');
    _bounded(performanceRatioPercent, 'performanceRatioPercent', 1, 100);
    _bounded(additionalLossPercent, 'additionalLossPercent', 0, 80);
    if (tariffInrPerKwh < 0 || !tariffInrPerKwh.isFinite) throw ArgumentError('Tariff cannot be negative.');
    final annual = dcCapacityKw * specificYieldKwhPerKwp * (performanceRatioPercent / 100) * (1 - additionalLossPercent / 100);
    const monthlyShares = [0.075, 0.078, 0.095, 0.096, 0.092, 0.083, 0.073, 0.074, 0.078, 0.087, 0.087, 0.082];
    final months = annual * monthlyShares.fold<double>(0, (a, b) => a + b);
    return EngineeringResult(
      title: 'Solar energy yield estimate', status: 'RESOURCE-BASED ESTIMATE',
      metrics: [
        EngineeringMetric('Annual generation', annual.toStringAsFixed(0), unit: 'kWh/year'),
        EngineeringMetric('Average monthly generation', (months / 12).toStringAsFixed(0), unit: 'kWh/month'),
        EngineeringMetric('Specific net yield', (annual / dcCapacityKw).toStringAsFixed(0), unit: 'kWh/kWp/year'),
        EngineeringMetric('Indicative annual value', '₹${(annual * tariffInrPerKwh).toStringAsFixed(0)}'),
      ],
      notes: const ['The monthly profile is a generic indicative distribution. Replace the specific-yield input with location- and source-attributed solar resource data and validate against a bankable simulation before financial commitment.'],
    );
  }

  static EngineeringResult calculateElectrical({
    required double moduleVocV,
    required double vocTempCoefficientPercentPerC,
    required double minimumTemperatureC,
    required double moduleVmpV,
    required double modulesPerString,
    required double stringCount,
    required double inverterMaxDcVoltageV,
    required double mpptMinVoltageV,
    required double mpptMaxVoltageV,
    required double inverterAcKw,
    required double cableCurrentA,
    required double cableLengthM,
    required double cableAreaMm2,
    required double systemVoltageV,
  }) {
    for (final entry in <(double, String)>[(moduleVocV,'moduleVocV'),(moduleVmpV,'moduleVmpV'),(modulesPerString,'modulesPerString'),(stringCount,'stringCount'),(inverterMaxDcVoltageV,'inverterMaxDcVoltageV'),(mpptMinVoltageV,'mpptMinVoltageV'),(mpptMaxVoltageV,'mpptMaxVoltageV'),(inverterAcKw,'inverterAcKw'),(cableCurrentA,'cableCurrentA'),(cableLengthM,'cableLengthM'),(cableAreaMm2,'cableAreaMm2'),(systemVoltageV,'systemVoltageV')]) { _positive(entry.$1, entry.$2); }
    _bounded(vocTempCoefficientPercentPerC.abs(), 'vocTempCoefficientPercentPerC', 0, 1);
    if (modulesPerString != modulesPerString.roundToDouble() || stringCount != stringCount.roundToDouble()) {
      throw ArgumentError('Modules per string and string count must be whole numbers.');
    }
    if (mpptMinVoltageV >= mpptMaxVoltageV) throw ArgumentError('MPPT minimum voltage must be below MPPT maximum voltage.');
    final temperatureRise = math.max(0, 25 - minimumTemperatureC);
    final coldVocPerModule = moduleVocV * (1 + vocTempCoefficientPercentPerC.abs() / 100 * temperatureRise);
    final coldStringVoc = coldVocPerModule * modulesPerString;
    final operatingStringVmp = moduleVmpV * modulesPerString;
    final cableDropV = 2 * cableLengthM * cableCurrentA * copperResistivityOhmMm2PerM / cableAreaMm2;
    final cableDropPercent = cableDropV / systemVoltageV * 100;
    final warnings = <String>[];
    if (coldStringVoc > inverterMaxDcVoltageV) warnings.add('Cold-corrected string Voc exceeds the inverter maximum DC voltage. Reduce series modules or select compatible equipment.');
    if (operatingStringVmp < mpptMinVoltageV || operatingStringVmp > mpptMaxVoltageV) warnings.add('Calculated string Vmp is outside the entered MPPT voltage window.');
    if (cableDropPercent > 2) warnings.add('Calculated resistive DC voltage drop exceeds 2%; review conductor sizing and the project design criterion.');
    if (minimumTemperatureC > 25) warnings.add('Minimum ambient temperature is above STC; confirm whether this value is the design minimum cell temperature basis.');
    return EngineeringResult(
      title: 'PV string and cable screening', status: warnings.isEmpty ? 'SCREENING CHECKS PASSED' : 'REVIEW REQUIRED',
      metrics: [
        EngineeringMetric('Cold-corrected module Voc', coldVocPerModule.toStringAsFixed(2), unit: 'V'),
        EngineeringMetric('Cold string Voc', coldStringVoc.toStringAsFixed(1), unit: 'V'),
        EngineeringMetric('String operating Vmp', operatingStringVmp.toStringAsFixed(1), unit: 'V'),
        EngineeringMetric('Strings entered', stringCount.toStringAsFixed(0)),
        EngineeringMetric('DC cable drop (simple DC model)', cableDropV.toStringAsFixed(2), unit: 'V'),
        EngineeringMetric('DC cable drop', cableDropPercent.toStringAsFixed(2), unit: '%'),
        EngineeringMetric('Inverter AC rating', inverterAcKw.toStringAsFixed(2), unit: 'kW'),
      ],
      notes: const ['String Vmp is calculated from the entered STC module Vmp without a temperature correction. The cable model is a simplified two-conductor DC copper resistive-drop estimate. This does not perform inverter input-current allocation, AC cable design, fault-current, protective-device coordination, earthing, lightning, transformer or utility-interconnection checks.'],
      warnings: warnings,
    );
  }

  static EngineeringResult calculateBattery({
    required double criticalLoadKw,
    required double autonomyHours,
    required double depthOfDischargePercent,
    required double roundTripEfficiencyPercent,
    required double nominalVoltageV,
    required double inverterContinuousKw,
  }) {
    _positive(criticalLoadKw, 'criticalLoadKw');
    _positive(autonomyHours, 'autonomyHours');
    _bounded(depthOfDischargePercent, 'depthOfDischargePercent', 1, 100);
    _bounded(roundTripEfficiencyPercent, 'roundTripEfficiencyPercent', 1, 100);
    _positive(nominalVoltageV, 'nominalVoltageV');
    _positive(inverterContinuousKw, 'inverterContinuousKw');
    final usableKwh = criticalLoadKw * autonomyHours;
    final nominalKwh = usableKwh / (depthOfDischargePercent / 100) / (roundTripEfficiencyPercent / 100);
    final ampHours = nominalKwh * 1000 / nominalVoltageV;
    final warnings = <String>[];
    if (criticalLoadKw > inverterContinuousKw) warnings.add('Critical load exceeds the entered inverter continuous rating.');
    return EngineeringResult(
      title: 'Battery storage sizing', status: warnings.isEmpty ? 'PRELIMINARY SIZING' : 'REVIEW INVERTER',
      metrics: [
        EngineeringMetric('Required usable energy', usableKwh.toStringAsFixed(2), unit: 'kWh'),
        EngineeringMetric('Minimum nominal battery energy', nominalKwh.toStringAsFixed(2), unit: 'kWh'),
        EngineeringMetric('Equivalent nominal capacity', ampHours.toStringAsFixed(1), unit: 'Ah @ ${nominalVoltageV.toStringAsFixed(0)} V'),
        EngineeringMetric('Inverter load ratio', '${(criticalLoadKw / inverterContinuousKw * 100).toStringAsFixed(1)}', unit: '%'),
      ],
      notes: const ['Energy-only estimate. Final battery design must check chemistry, C-rate, temperature, ageing, DC voltage range, inverter limits, surge load, BMS communication, short-circuit rating and manufacturer warranties.'],
      warnings: warnings,
    );
  }

  static EngineeringResult calculateWindScreen({
    required double designWindSpeedMps,
    required double forceCoefficient,
    required double effectiveAreaM2,
  }) {
    _bounded(designWindSpeedMps, 'designWindSpeedMps', 0.1, 150);
    _bounded(forceCoefficient, 'forceCoefficient', 0.1, 5);
    _positive(effectiveAreaM2, 'effectiveAreaM2');
    final pressurePa = 0.6 * designWindSpeedMps * designWindSpeedMps;
    final forceKn = pressurePa * forceCoefficient * effectiveAreaM2 / 1000;
    return EngineeringResult(
      title: 'Wind action screening', status: 'PRELIMINARY — ENGINEER REVIEW',
      metrics: [
        EngineeringMetric('Entered design wind speed', designWindSpeedMps.toStringAsFixed(1), unit: 'm/s'),
        EngineeringMetric('Reference velocity pressure', pressurePa.toStringAsFixed(1), unit: 'N/m²'),
        EngineeringMetric('Effective force coefficient', forceCoefficient.toStringAsFixed(2)),
        EngineeringMetric('Screening force', forceKn.toStringAsFixed(2), unit: 'kN'),
      ],
      notes: const ['Uses q = 0.6 V² as a basic velocity-pressure relationship only. It is not an IS 875 Part 3 design calculation. Terrain, risk, topography, height, pressure zones, internal pressure, load combinations, anchorage, members and connections are not evaluated.'],
      warnings: const ['Do not use this result for structural approval, fabrication or construction. A qualified structural engineer must establish the applicable code wind basis and complete the design.'],
    );
  }

  static List<BomLine> calculateBom({
    required int moduleCount,
    required double moduleWidthM,
    required double modulePowerW,
    required double inverterSizeKw,
    required double dcCableLengthM,
    required double acCableLengthM,
    required double moduleRate,
    required double inverterRate,
    required double railRatePerM,
    required double clampRate,
    required double cableRatePerM,
    required double earthingAllowance,
  }) {
    if (moduleCount < 0) throw ArgumentError('Module count cannot be negative.');
    _positive(moduleWidthM, 'moduleWidthM');
    _positive(modulePowerW, 'modulePowerW');
    _positive(inverterSizeKw, 'inverterSizeKw');
    for (final v in [dcCableLengthM, acCableLengthM, moduleRate, inverterRate, railRatePerM, clampRate, cableRatePerM, earthingAllowance]) {
      if (!v.isFinite || v < 0) throw ArgumentError('BOM quantities and rates cannot be negative.');
    }
    final dcKw = moduleCount * modulePowerW / 1000;
    final inverterCount = dcKw == 0 ? 0 : (dcKw / inverterSizeKw).ceil();
    final railMetres = moduleCount * moduleWidthM * 2;
    final clamps = moduleCount * 4;
    final lines = <BomLine>[
      BomLine(name: 'PV modules', quantity: moduleCount.toDouble(), unit: 'Nos', rate: moduleRate, amount: moduleCount * moduleRate, basis: 'Module count from entered design basis'),
      BomLine(name: 'String inverters', quantity: inverterCount.toDouble(), unit: 'Nos', rate: inverterRate, amount: inverterCount * inverterRate, basis: 'Rounded up from DC capacity / inverter size'),
      BomLine(name: 'Mounting rail allowance', quantity: railMetres, unit: 'm', rate: railRatePerM, amount: railMetres * railRatePerM, basis: '2 × module width per module; preliminary allowance'),
      BomLine(name: 'Module clamps allowance', quantity: clamps.toDouble(), unit: 'Nos', rate: clampRate, amount: clamps * clampRate, basis: '4 clamps per module allowance; verify rail and clamp design'),
      BomLine(name: 'DC cable', quantity: dcCableLengthM, unit: 'm', rate: cableRatePerM, amount: dcCableLengthM * cableRatePerM),
      BomLine(name: 'AC cable', quantity: acCableLengthM, unit: 'm', rate: cableRatePerM, amount: acCableLengthM * cableRatePerM),
      BomLine(name: 'Earthing / bonding allowance', quantity: 1, unit: 'Lot', rate: earthingAllowance, amount: earthingAllowance, basis: 'Budget allowance only; derive conductor and electrodes from design'),
    ];
    return lines;
  }

  static String createDxf({
    required double roofLengthM,
    required double roofWidthM,
    required int rows,
    required int columns,
    required double panelLengthM,
    required double panelWidthM,
    required double edgeSetbackM,
    required double walkwayWidthM,
    double moduleGapM = 0,
    Set<int> excludedCells = const {},
  }) {
    _positive(roofLengthM, 'roofLengthM');
    _positive(roofWidthM, 'roofWidthM');
    _positive(panelLengthM, 'panelLengthM');
    _positive(panelWidthM, 'panelWidthM');
    if (rows < 0 || columns < 0) throw ArgumentError('Rows and columns cannot be negative.');
    if (!edgeSetbackM.isFinite || !walkwayWidthM.isFinite || !moduleGapM.isFinite ||
        edgeSetbackM < 0 || walkwayWidthM < 0 || moduleGapM < 0) {
      throw ArgumentError('Setbacks, walkway and module gap must be finite and non-negative.');
    }
    if (edgeSetbackM * 2 >= roofLengthM || edgeSetbackM * 2 + walkwayWidthM >= roofWidthM) {
      throw ArgumentError('Setbacks and walkway leave no usable roof area.');
    }
    final b = StringBuffer('0\nSECTION\n2\nHEADER\n9\n\$INSUNITS\n70\n6\nENDSEC\n0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n2\n0\nLAYER\n2\nROOF\n70\n0\n62\n7\n6\nCONTINUOUS\n0\nLAYER\n2\nPV_MODULE\n70\n0\n62\n3\n6\nCONTINUOUS\n0\nENDTAB\n0\nENDSEC\n0\nSECTION\n2\nENTITIES\n');
    void line(double x1, double y1, double x2, double y2, String layer) {
      b.write('0\nLINE\n8\n$layer\n10\n${x1.toStringAsFixed(4)}\n20\n${y1.toStringAsFixed(4)}\n30\n0\n11\n${x2.toStringAsFixed(4)}\n21\n${y2.toStringAsFixed(4)}\n31\n0\n');
    }
    line(0, 0, roofLengthM, 0, 'ROOF');
    line(roofLengthM, 0, roofLengthM, roofWidthM, 'ROOF');
    line(roofLengthM, roofWidthM, 0, roofWidthM, 'ROOF');
    line(0, roofWidthM, 0, 0, 'ROOF');
    final freeWidth = roofWidthM - 2 * edgeSetbackM - walkwayWidthM;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final index = row * columns + col;
        if (excludedCells.contains(index)) continue;
        final x = edgeSetbackM + row * (panelLengthM + moduleGapM);
        final y = edgeSetbackM + walkwayWidthM + col * (panelWidthM + moduleGapM);
        if (x + panelLengthM > roofLengthM - edgeSetbackM || y + panelWidthM > edgeSetbackM + walkwayWidthM + freeWidth) continue;
        line(x, y, x + panelLengthM, y, 'PV_MODULE');
        line(x + panelLengthM, y, x + panelLengthM, y + panelWidthM, 'PV_MODULE');
        line(x + panelLengthM, y + panelWidthM, x, y + panelWidthM, 'PV_MODULE');
        line(x, y + panelWidthM, x, y, 'PV_MODULE');
      }
    }
    b.write('0\nENDSEC\n0\nEOF\n');
    return b.toString();
  }
}
