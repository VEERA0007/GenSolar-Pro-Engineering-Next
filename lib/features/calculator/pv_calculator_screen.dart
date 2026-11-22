import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../core/engineering/solar_calculators.dart';
import '../../shared/widgets/section_heading.dart';

class PvCalculatorScreen extends StatefulWidget {
  const PvCalculatorScreen({super.key});

  @override
  State<PvCalculatorScreen> createState() => _PvCalculatorScreenState();
}

class _PvCalculatorScreenState extends State<PvCalculatorScreen> {
  final _capacity = TextEditingController(text: '10');
  final _modulePower = TextEditingController(text: '550');
  final _length = TextEditingController(text: '2.278');
  final _width = TextEditingController(text: '1.134');
  final _roofArea = TextEditingController(text: '120');
  PvSizingResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _capacity.dispose();
    _modulePower.dispose();
    _length.dispose();
    _width.dispose();
    _roofArea.dispose();
    super.dispose();
  }

  void _calculate() {
    final capacity = double.tryParse(_capacity.text.trim());
    final watt = double.tryParse(_modulePower.text.trim());
    final length = double.tryParse(_length.text.trim());
    final width = double.tryParse(_width.text.trim());
    final roofText = _roofArea.text.trim();
    final roof = roofText.isEmpty ? null : double.tryParse(roofText);
    if (capacity == null || watt == null || length == null || width == null ||
        (roofText.isNotEmpty && roof == null)) {
      setState(() {
        _result = null;
        _error = 'Enter valid numeric values in all fields.';
      });
      return;
    }
    try {
      final result = SolarCalculators.calculatePvSizing(
        targetCapacityKw: capacity,
        modulePowerW: watt,
        moduleLengthM: length,
        moduleWidthM: width,
        availableRoofAreaM2: roof,
      );
      setState(() {
        _result = result;
        _error = null;
      });
    } on ArgumentError catch (error) {
      setState(() {
        _result = null;
        _error = error.message?.toString() ?? 'Check the entered values.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(title: 'PV module sizing'),
                const SizedBox(height: 6),
                Text('Quick capacity, module-count and preliminary roof-area estimate.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Design inputs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        LayoutBuilder(builder: (context, constraints) {
                          final columns = constraints.maxWidth > 620 ? 2 : 1;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 4,
                            childAspectRatio: columns == 1 ? 5.2 : 4.2,
                            children: [
                              _NumberInput(label: 'Target DC capacity (kW)', controller: _capacity, onChanged: _calculate),
                              _NumberInput(label: 'Module rating (Wp)', controller: _modulePower, onChanged: _calculate),
                              _NumberInput(label: 'Module length (m)', controller: _length, onChanged: _calculate),
                              _NumberInput(label: 'Module width (m)', controller: _width, onChanged: _calculate),
                              _NumberInput(label: 'Available roof area (m²)', controller: _roofArea, onChanged: _calculate, optional: true),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),
                        FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('Calculate PV sizing')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_error != null)
                  Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                  )),
                if (_result case final result?) ...[
                  const SectionHeading(title: 'Calculated estimate'),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth > 680 ? 3 : 2;
                    final values = [
                      ('Modules required', NumberFormat('#,##0').format(result.moduleCount), Icons.grid_view),
                      ('Installed DC capacity', '${result.installedCapacityKw.toStringAsFixed(2)} kW', Icons.solar_power),
                      ('Module surface area', '${result.moduleAreaM2.toStringAsFixed(1)} m²', Icons.square_foot),
                      ('Planning area', '${result.planningAreaM2.toStringAsFixed(1)} m²', Icons.roofing),
                      ('Area in sq.ft', '${(result.planningAreaM2 * 10.7639104167).toStringAsFixed(0)} sq.ft', Icons.straighten),
                      ('Roof area utilization', result.roofUtilizationPercent == null ? 'Not entered' : '${result.roofUtilizationPercent!.toStringAsFixed(1)}%', Icons.pie_chart_outline),
                    ];
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: constraints.maxWidth < 400 ? 1.35 : 1.65,
                      children: values.map((item) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(item.$3, color: Theme.of(context).colorScheme.primary),
                            const Spacer(),
                            Text(item.$2, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ),
                      )).toList(),
                    );
                  }),
                  if (result.roofUtilizationPercent != null && result.roofUtilizationPercent! > 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Warning: estimated planning area exceeds the entered roof area. Review setbacks, walkways, obstacles and actual module layout.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
                    ),
                ],
                const SizedBox(height: 18),
                const _EngineeringNote(),
              ],
            ),
          ),
        ),
      );
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({required this.label, required this.controller, required this.onChanged, this.optional = false});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: optional ? '$label (optional)' : label),
      );
}

class _EngineeringNote extends StatelessWidget {
  const _EngineeringNote();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(child: Text('Planning estimate only. The area factor is an allowance, not a layout engine. Final fit must account for roof polygons, orientation, module clamps, fire access, edge setbacks, obstacles, structural limits and applicable local requirements.')),
          ]),
        ),
      );
}
