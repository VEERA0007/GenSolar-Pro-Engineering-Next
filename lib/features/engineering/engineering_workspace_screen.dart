import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/theme.dart';
import '../../core/engineering/engineering_workflows.dart';
import '../../core/models/solar_project.dart';
import '../../core/providers.dart';
import '../../shared/widgets/section_heading.dart';

class EngineeringWorkspaceScreen extends ConsumerStatefulWidget {
  const EngineeringWorkspaceScreen({super.key});

  @override
  ConsumerState<EngineeringWorkspaceScreen> createState() => _EngineeringWorkspaceScreenState();
}

class _EngineeringWorkspaceScreenState extends ConsumerState<EngineeringWorkspaceScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedProjectId;
  bool _saving = false;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this, initialIndex: ref.read(activeWorkspaceTabProvider));
    _tabController.addListener(_syncWorkspaceTab);
  }

  void _syncWorkspaceTab() {
    if (!_tabController.indexIsChanging) {
      final current = ref.read(activeWorkspaceTabProvider);
      if (current != _tabController.index) {
        ref.read(activeWorkspaceTabProvider.notifier).select(_tabController.index);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncWorkspaceTab);
    _tabController.dispose();
    super.dispose();
  }

  Map<String, Object?> _section(SolarProject project, String key) {
    final value = project.engineeringData[key];
    return value is Map ? Map<String, Object?>.from(value) : <String, Object?>{};
  }

  Future<void> _saveSection(SolarProject project, String key, Map<String, Object?> values) {
    final operation = _saveQueue.then((_) async {
      if (!mounted) return;
      setState(() => _saving = true);
      try {
        final repository = ref.read(projectRepositoryProvider);
        final latestProjects = await repository.loadAll();
        final matches = latestProjects.where((item) => item.id == project.id);
        if (matches.isEmpty) throw StateError('This project was deleted before the workspace save completed.');
        final latest = matches.first;
        final next = markDownstreamReview(latest.engineeringData, key);
        next[key] = <String, Object?>{
          ...values,
          'needsReview': values['needsReview'] == true,
          'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'schemaVersion': 1,
        };
        final updated = latest.copyWith(
          engineeringData: next,
          targetCapacityKw: key == 'pv'
              ? _asDouble(values['targetCapacityKw'], latest.targetCapacityKw)
              : null,
          status: deriveProjectStatus(next),
          updatedAt: DateTime.now().toUtc(),
        );
        await repository.save(updated);
        ref.invalidate(projectsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_prettyName(key)} saved. Related downstream sections were flagged for review where required.')),
          );
        }
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $error')));
        rethrow;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
    _saveQueue = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  String _prettyName(String key) => switch (key) {
    'survey' => 'Site survey', 'pv' => 'PV layout', 'yield' => 'Solar yield',
    'electrical' => 'Electrical design', 'battery' => 'Battery sizing',
    'structural' => 'Wind screening', 'bom' => 'BOM / BOQ',
    'delivery' => 'Delivery checklist', 'procurement' => 'Procurement record',
    'cad' => 'CAD plan', 'report' => 'DPR report', _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final activeWorkspaceTab = ref.watch(activeWorkspaceTabProvider);
    ref.listen<int>(activeWorkspaceTabProvider, (previous, next) {
      if (next != _tabController.index) _tabController.animateTo(next, duration: const Duration(milliseconds: 240));
    });
    final activeProjectId = ref.watch(activeProjectIdProvider);
    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load projects: $error'))),
      data: (projects) {
        if (projects.isEmpty) return const _NoProjectWorkspace();
        SolarProject project = projects.first;
        final preferredId = activeProjectId ?? _selectedProjectId;
        for (final item in projects) {
          if (item.id == preferredId) { project = item; break; }
        }
        if (_selectedProjectId != project.id) _selectedProjectId = project.id;
        if (activeProjectId != project.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.read(activeProjectIdProvider.notifier).select(project.id);
          });
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE4EBE6)))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Engineering workflow', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text('One project record shared across design, calculations, procurement and handover.', style: Theme.of(context).textTheme.bodySmall),
                  ])),
                  const SizedBox(width: 12),
                  if (_saving)
                    const Chip(avatar: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)), label: Text('Saving'))
                  else
                    const Chip(avatar: Icon(Icons.cloud_done_outlined, size: 16), label: Text('Local data saved')),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: project.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Active EPC project', prefixIcon: Icon(Icons.folder_open), isDense: true),
                  items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name}  ·  ${p.targetCapacityKw.toStringAsFixed(1)} kWp', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) {
                    setState(() => _selectedProjectId = value);
                    ref.read(activeProjectIdProvider.notifier).select(value);
                  },
                ),
                const SizedBox(height: 12),
                _ProjectWorkflowRail(
                  project: project,
                  selectedIndex: activeWorkspaceTab,
                  onSelect: (index) => ref.read(activeWorkspaceTabProvider.notifier).select(index),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  onTap: (index) => ref.read(activeWorkspaceTabProvider.notifier).select(index),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                Tab(icon: Icon(Icons.location_on_outlined), text: 'Survey'),
                Tab(icon: Icon(Icons.solar_power_outlined), text: 'PV Layout'),
                Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'Yield'),
                Tab(icon: Icon(Icons.electrical_services_outlined), text: 'Electrical'),
                Tab(icon: Icon(Icons.battery_charging_full), text: 'Battery'),
                Tab(icon: Icon(Icons.architecture), text: 'Wind'),
                Tab(icon: Icon(Icons.inventory_2_outlined), text: 'BOM / BOQ'),
                Tab(icon: Icon(Icons.construction_outlined), text: 'Delivery'),
                Tab(icon: Icon(Icons.draw), text: 'CAD'),
                Tab(icon: Icon(Icons.description_outlined), text: 'DPR'),
                  ],
                ),
              ]),
            ),
            Expanded(child: TabBarView(controller: _tabController, children: [
              _CalculationTab(key: ValueKey('${project.id}-survey'), project: project, section: 'survey', initialData: _section(project, 'survey'), definition: _surveyDefinition, onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(1)),
              _CalculationTab(key: ValueKey('${project.id}-pv'), project: project, section: 'pv', initialData: _pvInitial(project), definition: _pvDefinition, onSave: _saveSection, allowManualPlacement: true, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(2)),
              _CalculationTab(key: ValueKey('${project.id}-yield'), project: project, section: 'yield', initialData: _yieldInitial(project), definition: _yieldDefinition, onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(3)),
              _CalculationTab(key: ValueKey('${project.id}-electrical'), project: project, section: 'electrical', initialData: _electricalInitial(project), definition: _electricalDefinition, onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(4)),
              _CalculationTab(key: ValueKey('${project.id}-battery'), project: project, section: 'battery', initialData: {..._batteryDefinition.defaults, ..._section(project, 'battery')}, definition: _batteryDefinition, onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(5)),
              _CalculationTab(key: ValueKey('${project.id}-structural'), project: project, section: 'structural', initialData: _structuralInitial(project), definition: _structuralDefinition, onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(6)),
              _CalculationTab(key: ValueKey('${project.id}-bom'), project: project, section: 'bom', initialData: _bomInitial(project), definition: _bomDefinition, onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(7)),
              _DeliveryTab(key: ValueKey('${project.id}-delivery'), project: project, initialData: _section(project, 'delivery'), procurementData: _section(project, 'procurement'), onSave: _saveSection, onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(8)),
              _CadTab(key: ValueKey('${project.id}-cad'), project: project, onSave: (values) => _saveSection(project, 'cad', values), onReviewPv: () => ref.read(activeWorkspaceTabProvider.notifier).select(1), onNext: () => ref.read(activeWorkspaceTabProvider.notifier).select(9)),
              _ReportTab(key: ValueKey('${project.id}-report'), project: project, onSave: (values) => _saveSection(project, 'report', values)),
            ])),
          ]),
      },
    );
  }

  Map<String, Object?> _pvInitial(SolarProject project) {
    final survey = _section(project, 'survey');
    final existing = _section(project, 'pv');
    final stale = existing['needsReview'] == true;
    final savedTarget = existing['targetCapacityKw'];
    final targetChanged = savedTarget is num && project.targetCapacityKw > 0 &&
        (savedTarget - project.targetCapacityKw).abs() > 0.001;
    return {
      ..._pvDefinition.defaults,
      ...existing,
      // A project-level target edit is authoritative. Do not silently refill
      // the PV form with its old saved target when the section is stale.
      'targetCapacityKw': targetChanged
          ? project.targetCapacityKw
          : (existing['targetCapacityKw'] ?? (project.targetCapacityKw > 0 ? project.targetCapacityKw : _pvDefinition.defaults['targetCapacityKw'])),
      'roofLengthM': stale ? (survey['roofLengthM'] ?? existing['roofLengthM'] ?? _pvDefinition.defaults['roofLengthM']) : (existing['roofLengthM'] ?? survey['roofLengthM'] ?? _pvDefinition.defaults['roofLengthM']),
      'roofWidthM': stale ? (survey['roofWidthM'] ?? existing['roofWidthM'] ?? _pvDefinition.defaults['roofWidthM']) : (existing['roofWidthM'] ?? survey['roofWidthM'] ?? _pvDefinition.defaults['roofWidthM']),
      'edgeSetbackM': stale ? (survey['edgeSetbackM'] ?? existing['edgeSetbackM'] ?? _pvDefinition.defaults['edgeSetbackM']) : (existing['edgeSetbackM'] ?? survey['edgeSetbackM'] ?? _pvDefinition.defaults['edgeSetbackM']),
      'walkwayWidthM': stale ? (survey['walkwayWidthM'] ?? existing['walkwayWidthM'] ?? _pvDefinition.defaults['walkwayWidthM']) : (existing['walkwayWidthM'] ?? survey['walkwayWidthM'] ?? _pvDefinition.defaults['walkwayWidthM']),
      'manualExcludedCells': (existing['reviewReason']?.toString().toLowerCase().contains('survey') ?? false)
          ? <int>[]
          : (existing['manualExcludedCells'] ?? <int>[]),
    };
  }

  int _pvModuleCount(Map<String, Object?> pv) {
    final result = pv['calculationResult'];
    if (result is Map && result['moduleCount'] is num) return (result['moduleCount'] as num).toInt();
    return 0;
  }

  double _pvInstalledKw(Map<String, Object?> pv, SolarProject project) {
    // Never use a stale saved PV layout as a current yield input. The project
    // target is a provisional prefill until the PV layout has been recalculated.
    if (pv['needsReview'] == true) {
      return project.targetCapacityKw > 0 ? project.targetCapacityKw : 10;
    }
    final count = _pvModuleCount(pv);
    final power = _asDouble(pv['modulePowerW'], 550);
    return count > 0 ? count * power / 1000 : (project.targetCapacityKw > 0 ? project.targetCapacityKw : 10);
  }

  Map<String, Object?> _yieldInitial(SolarProject project) {
    final pv = _section(project, 'pv');
    final existing = _section(project, 'yield');
    final base = _pvInstalledKw(pv, project);
    return {
      ..._yieldDefinition.defaults,
      ...existing,
      'dcCapacityKw': existing['needsReview'] == true ? base : (existing['dcCapacityKw'] ?? base),
    };
  }

  Map<String, Object?> _electricalInitial(SolarProject project) {
    final pv = _section(project, 'pv');
    final existing = _section(project, 'electrical');
    final modulePower = _asDouble(pv['modulePowerW'], 550);
    final savedModuleCount = _pvModuleCount(pv);
    final moduleCount = pv['needsReview'] == true
        ? ((project.targetCapacityKw > 0 ? project.targetCapacityKw : 10) * 1000 / modulePower).ceil()
        : savedModuleCount;
    final modulesPerString = _asDouble(existing['modulesPerString'], 18).round().clamp(1, 1000);
    final inferredStrings = moduleCount == 0 ? 4 : (moduleCount / modulesPerString).ceil().clamp(1, 1000);
    return {
      ..._electricalDefinition.defaults,
      ...existing,
      'stringCount': existing['needsReview'] == true ? inferredStrings : (existing['stringCount'] ?? inferredStrings),
    };
  }

  Map<String, Object?> _structuralInitial(SolarProject project) {
    final survey = _section(project, 'survey');
    final existing = _section(project, 'structural');
    final roofArea = _asDouble(survey['roofLengthM'], 30) * _asDouble(survey['roofWidthM'], 20);
    return {
      ..._structuralDefinition.defaults,
      ...existing,
      'effectiveAreaM2': existing['needsReview'] == true ? roofArea : (existing['effectiveAreaM2'] ?? roofArea),
    };
  }

  Map<String, Object?> _bomInitial(SolarProject project) {
    final pv = _section(project, 'pv');
    final electrical = _section(project, 'electrical');
    final existing = _section(project, 'bom');
    final power = _asDouble(pv['modulePowerW'], 550);
    final savedCount = _pvModuleCount(pv);
    final target = project.targetCapacityKw > 0 ? project.targetCapacityKw : 10.0;
    final count = pv['needsReview'] == true ? 0 : savedCount;
    final defaultCount = count > 0 ? count : (target * 1000 / power).ceil();
    return {
      ..._bomDefinition.defaults,
      ...existing,
      'moduleCount': existing['needsReview'] == true ? defaultCount : (existing['moduleCount'] ?? defaultCount),
      'modulePowerW': existing['needsReview'] == true ? power : (existing['modulePowerW'] ?? power),
      'moduleWidthM': existing['needsReview'] == true ? _asDouble(pv['moduleWidthM'], 1.134) : (existing['moduleWidthM'] ?? _asDouble(pv['moduleWidthM'], 1.134)),
      'dcCableLengthM': existing['needsReview'] == true ? _asDouble(electrical['cableLengthM'], 100) : (existing['dcCableLengthM'] ?? _asDouble(electrical['cableLengthM'], 100)),
    };
  }
}

class _ProjectWorkflowRail extends StatelessWidget {
  const _ProjectWorkflowRail({required this.project, required this.selectedIndex, required this.onSelect});
  final SolarProject project;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _steps = <(String, String, IconData)>[
    ('Survey', 'survey', Icons.location_on_outlined),
    ('PV layout', 'pv', Icons.grid_view_rounded),
    ('Yield', 'yield', Icons.wb_sunny_outlined),
    ('Electrical', 'electrical', Icons.electrical_services_outlined),
    ('Battery', 'battery', Icons.battery_charging_full_outlined),
    ('Wind', 'structural', Icons.architecture_outlined),
    ('BOM', 'bom', Icons.inventory_2_outlined),
    ('Procurement + delivery', 'delivery', Icons.local_shipping_outlined),
    ('CAD', 'cad', Icons.draw_outlined),
    ('DPR', 'report', Icons.description_outlined),
  ];

  Map<String, Object?> _data(String key) {
    final value = project.engineeringData[key];
    return value is Map ? Map<String, Object?>.from(value) : <String, Object?>{};
  }

  bool _isCaptured(String key) {
    if (key == 'cad' || key == 'report') return _data(key).isNotEmpty;
    if (key == 'delivery') return _data('delivery').isNotEmpty && _data('procurement').isNotEmpty;
    return _data(key).isNotEmpty;
  }

  bool _needsReview(String key) {
    if (key == 'cad' || key == 'report') return _data(key)['needsReview'] == true;
    if (key == 'delivery') return _data('delivery')['needsReview'] == true || _data('procurement')['needsReview'] == true;
    return _data(key)['needsReview'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final captured = _steps.where((step) => _isCaptured(step.$2) && !_needsReview(step.$2)).length;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('PROJECT DELIVERY FLOW', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0, color: colorScheme.onSurfaceVariant))),
            Text('$captured / ${_steps.length} captured', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: GenSolarTheme.brandGreen)),
          ]),
          const SizedBox(height: 7),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: captured / _steps.length, minHeight: 5, backgroundColor: colorScheme.surfaceContainerHighest)),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var index = 0; index < _steps.length; index++) ...[
                _WorkflowStepButton(
                  title: _steps[index].$1,
                  icon: _steps[index].$3,
                  selected: index == selectedIndex,
                  captured: _isCaptured(_steps[index].$2),
                  review: _needsReview(_steps[index].$2),
                  onTap: () => onSelect(index),
                ),
                if (index != _steps.length - 1)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 16, color: colorScheme.outline)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _WorkflowStepButton extends StatelessWidget {
  const _WorkflowStepButton({required this.title, required this.icon, required this.selected, required this.captured, required this.review, required this.onTap});
  final String title;
  final IconData icon;
  final bool selected;
  final bool captured;
  final bool review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = selected ? scheme.primaryContainer : review ? scheme.errorContainer.withValues(alpha: .55) : captured ? const Color(0xFFE4F3E9) : scheme.surface;
    final foreground = selected ? scheme.onPrimaryContainer : review ? scheme.error : captured ? const Color(0xFF176B4A) : scheme.onSurfaceVariant;
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(review ? Icons.refresh_rounded : captured ? Icons.check_circle_rounded : icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: foreground)),
          ]),
        ),
      ),
    );
  }
}

class _NoProjectWorkspace extends ConsumerWidget {
  const _NoProjectWorkspace();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18)), child: Icon(Icons.solar_power_rounded, size: 34, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 14),
      Text('Create an EPC project first', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('The engineering workspace is project-based. Create a site record first, then the survey, PV, yield, electrical, material and delivery sections will use the same project data.', textAlign: TextAlign.center),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: () => ref.read(appNavigationIndexProvider.notifier).select(1), icon: const Icon(Icons.add), label: const Text('Create a project')),
    ]))),
  ));
}

class _FieldDefinition {
  const _FieldDefinition(this.key, this.label, this.unit, this.initial, {this.min, this.max, this.help});
  final String key;
  final String label;
  final String unit;
  final double initial;
  final double? min;
  final double? max;
  final String? help;
}

typedef _CalculationFunction = EngineeringResult Function(Map<String, double> values, List<int> excluded);

class _ModuleDefinition {
  const _ModuleDefinition({required this.title, required this.description, required this.fields, required this.calculate});
  final String title;
  final String description;
  final List<_FieldDefinition> fields;
  final _CalculationFunction calculate;
  Map<String, Object?> get defaults => {for (final f in fields) f.key: f.initial};
}

final _surveyDefinition = _ModuleDefinition(
  title: 'Site survey & roof zone',
  description: 'Capture the basic site location and one rectangular roof zone. Add additional roof zones as separate design projects until the multi-zone editor is implemented.',
  fields: [
    _FieldDefinition('latitude', 'Latitude (sample)', '°', 17.3850, min: -90, max: 90, help: 'Example coordinate only. Replace with verified site GPS.'),
    _FieldDefinition('longitude', 'Longitude (sample)', '°', 78.4867, min: -180, max: 180, help: 'Example coordinate only. Replace with verified site GPS.'),
    _FieldDefinition('elevationM', 'Site elevation', 'm', 540),
    _FieldDefinition('roofLengthM', 'Roof length', 'm', 30, min: 0.1),
    _FieldDefinition('roofWidthM', 'Roof width', 'm', 20, min: 0.1),
    _FieldDefinition('roofTiltDeg', 'Roof tilt', '°', 5, min: 0, max: 60),
    _FieldDefinition('edgeSetbackM', 'Edge setback', 'm', 0.5, min: 0),
    _FieldDefinition('walkwayWidthM', 'Access walkway width', 'm', 1, min: 0),
  ],
  calculate: (v, _) => SolarCalculators.calculateSurvey(
    latitude: v['latitude']!, longitude: v['longitude']!, elevationM: v['elevationM']!,
    roofLengthM: v['roofLengthM']!, roofWidthM: v['roofWidthM']!, roofTiltDeg: v['roofTiltDeg']!,
    edgeSetbackM: v['edgeSetbackM']!, walkwayWidthM: v['walkwayWidthM']!,
  ),
);

final _pvDefinition = _ModuleDefinition(
  title: 'PV module layout',
  description: 'Rectangular portrait/landscape fit screening with edge clearance, access strip, inter-module gap and manual cell exclusions.',
  fields: [
    _FieldDefinition('targetCapacityKw', 'Target DC capacity', 'kWp', 10, min: 0.1),
    _FieldDefinition('roofLengthM', 'Roof length', 'm', 30, min: 0.1),
    _FieldDefinition('roofWidthM', 'Roof width', 'm', 20, min: 0.1),
    _FieldDefinition('modulePowerW', 'Module rating', 'Wp', 550, min: 1),
    _FieldDefinition('moduleLengthM', 'Module long side', 'm', 2.278, min: 0.1),
    _FieldDefinition('moduleWidthM', 'Module short side', 'm', 1.134, min: 0.1),
    _FieldDefinition('edgeSetbackM', 'Edge setback', 'm', 0.5, min: 0),
    _FieldDefinition('walkwayWidthM', 'Walkway strip', 'm', 1, min: 0),
    _FieldDefinition('moduleGapM', 'Module-to-module gap', 'm', 0.03, min: 0),
  ],
  calculate: (v, excluded) => SolarCalculators.calculateRectangularPvLayout(
    roofLengthM: v['roofLengthM']!, roofWidthM: v['roofWidthM']!, modulePowerW: v['modulePowerW']!,
    moduleLengthM: v['moduleLengthM']!, moduleWidthM: v['moduleWidthM']!, edgeSetbackM: v['edgeSetbackM']!,
    walkwayWidthM: v['walkwayWidthM']!, moduleGapM: v['moduleGapM']!, targetCapacityKw: v['targetCapacityKw']!,
    excludedCellIndexes: excluded,
  ),
);

final _yieldDefinition = _ModuleDefinition(
  title: 'Solar resource & yield',
  description: 'Annual yield and indicative annual value from a user-supplied specific-yield assumption, PR, additional loss and electricity tariff.',
  fields: [
    _FieldDefinition('dcCapacityKw', 'Installed DC capacity', 'kWp', 10, min: 0.1),
    _FieldDefinition('specificYieldKwhPerKwp', 'Gross specific yield assumption', 'kWh/kWp/year', 1600, min: 1),
    _FieldDefinition('performanceRatioPercent', 'Performance ratio', '%', 80, min: 1, max: 100),
    _FieldDefinition('additionalLossPercent', 'Additional loss allowance', '%', 5, min: 0, max: 80),
    _FieldDefinition('tariffInrPerKwh', 'Energy tariff', 'INR/kWh', 8, min: 0),
  ],
  calculate: (v, _) => SolarCalculators.calculateYield(
    dcCapacityKw: v['dcCapacityKw']!, specificYieldKwhPerKwp: v['specificYieldKwhPerKwp']!,
    performanceRatioPercent: v['performanceRatioPercent']!, additionalLossPercent: v['additionalLossPercent']!,
    tariffInrPerKwh: v['tariffInrPerKwh']!,
  ),
);

final _electricalDefinition = _ModuleDefinition(
  title: 'PV strings & DC cable',
  description: 'Cold-corrected string Voc, MPPT voltage-window screening and simplified DC copper cable voltage drop.',
  fields: [
    _FieldDefinition('moduleVocV', 'Module Voc at STC', 'V', 49.5, min: 0.1),
    _FieldDefinition('vocTempCoefficientPercentPerC', 'Voc temperature coefficient magnitude', '%/°C', 0.28, min: 0, max: 1),
    _FieldDefinition('minimumTemperatureC', 'Design minimum temperature', '°C', 5, min: -60, max: 60),
    _FieldDefinition('moduleVmpV', 'Module Vmp at STC', 'V', 41.5, min: 0.1),
    _FieldDefinition('modulesPerString', 'Modules in series', 'Nos', 18, min: 1),
    _FieldDefinition('stringCount', 'Parallel strings entered', 'Nos', 4, min: 1),
    _FieldDefinition('inverterMaxDcVoltageV', 'Inverter maximum DC voltage', 'V', 1100, min: 1),
    _FieldDefinition('mpptMinVoltageV', 'MPPT minimum voltage', 'V', 180, min: 1),
    _FieldDefinition('mpptMaxVoltageV', 'MPPT maximum voltage', 'V', 1000, min: 1),
    _FieldDefinition('inverterAcKw', 'Inverter AC rating', 'kW', 10, min: 0.1),
    _FieldDefinition('cableCurrentA', 'DC cable current', 'A', 15, min: 0.1),
    _FieldDefinition('cableLengthM', 'One-way cable length', 'm', 35, min: 0.1),
    _FieldDefinition('cableAreaMm2', 'Copper cable cross-section', 'mm²', 6, min: 0.1),
    _FieldDefinition('systemVoltageV', 'DC operating voltage for drop', 'V', 750, min: 1),
  ],
  calculate: (v, _) => SolarCalculators.calculateElectrical(
    moduleVocV: v['moduleVocV']!, vocTempCoefficientPercentPerC: v['vocTempCoefficientPercentPerC']!,
    minimumTemperatureC: v['minimumTemperatureC']!, moduleVmpV: v['moduleVmpV']!,
    modulesPerString: v['modulesPerString']!, stringCount: v['stringCount']!,
    inverterMaxDcVoltageV: v['inverterMaxDcVoltageV']!, mpptMinVoltageV: v['mpptMinVoltageV']!,
    mpptMaxVoltageV: v['mpptMaxVoltageV']!, inverterAcKw: v['inverterAcKw']!,
    cableCurrentA: v['cableCurrentA']!, cableLengthM: v['cableLengthM']!,
    cableAreaMm2: v['cableAreaMm2']!, systemVoltageV: v['systemVoltageV']!,
  ),
);

final _batteryDefinition = _ModuleDefinition(
  title: 'Battery & hybrid sizing',
  description: 'Energy requirement and equivalent nominal amp-hour capacity based on critical load, autonomy, DoD and efficiency.',
  fields: [
    _FieldDefinition('criticalLoadKw', 'Critical load', 'kW', 5, min: 0.1),
    _FieldDefinition('autonomyHours', 'Required autonomy', 'hours', 4, min: 0.1),
    _FieldDefinition('depthOfDischargePercent', 'Usable depth of discharge', '%', 80, min: 1, max: 100),
    _FieldDefinition('roundTripEfficiencyPercent', 'Battery/system efficiency allowance', '%', 90, min: 1, max: 100),
    _FieldDefinition('nominalVoltageV', 'Battery nominal DC voltage', 'V', 512, min: 1),
    _FieldDefinition('inverterContinuousKw', 'Inverter continuous rating', 'kW', 6, min: 0.1),
  ],
  calculate: (v, _) => SolarCalculators.calculateBattery(
    criticalLoadKw: v['criticalLoadKw']!, autonomyHours: v['autonomyHours']!,
    depthOfDischargePercent: v['depthOfDischargePercent']!, roundTripEfficiencyPercent: v['roundTripEfficiencyPercent']!,
    nominalVoltageV: v['nominalVoltageV']!, inverterContinuousKw: v['inverterContinuousKw']!,
  ),
);

final _structuralDefinition = _ModuleDefinition(
  title: 'Wind action screening',
  description: 'A basic velocity-pressure relationship for preliminary awareness only. It is not a code-compliant structural design or approval.',
  fields: [
    _FieldDefinition('designWindSpeedMps', 'Entered design wind speed', 'm/s', 39, min: 0.1),
    _FieldDefinition('forceCoefficient', 'Assumed force coefficient', '—', 1.5, min: 0.1),
    _FieldDefinition('effectiveAreaM2', 'Effective exposed area', 'm²', 30, min: 0.1),
  ],
  calculate: (v, _) => SolarCalculators.calculateWindScreen(
    designWindSpeedMps: v['designWindSpeedMps']!, forceCoefficient: v['forceCoefficient']!, effectiveAreaM2: v['effectiveAreaM2']!,
  ),
);

final _bomDefinition = _ModuleDefinition(
  title: 'BOM / BOQ & budget estimate',
  description: 'Editable rate-based preliminary quantity and material budget schedule. Confirm equipment selections and actual routing before procurement.',
  fields: [
    _FieldDefinition('moduleCount', 'PV module quantity', 'Nos', 18, min: 0),
    _FieldDefinition('modulePowerW', 'Module rating', 'Wp', 550, min: 1),
    _FieldDefinition('moduleWidthM', 'Module short side', 'm', 1.134, min: 0.1),
    _FieldDefinition('inverterSizeKw', 'Inverter unit rating', 'kW', 10, min: 0.1),
    _FieldDefinition('dcCableLengthM', 'DC cable quantity', 'm', 100, min: 0),
    _FieldDefinition('acCableLengthM', 'AC cable quantity', 'm', 40, min: 0),
    _FieldDefinition('moduleRate', 'Module rate', 'INR/No', 9500, min: 0),
    _FieldDefinition('inverterRate', 'Inverter rate', 'INR/No', 95000, min: 0),
    _FieldDefinition('railRatePerM', 'Rail rate', 'INR/m', 450, min: 0),
    _FieldDefinition('clampRate', 'Clamp rate', 'INR/No', 35, min: 0),
    _FieldDefinition('cableRatePerM', 'Cable blended rate', 'INR/m', 80, min: 0),
    _FieldDefinition('earthingAllowance', 'Earthing/bonding budget', 'INR/Lot', 25000, min: 0),
  ],
  calculate: (v, _) {
    final lines = SolarCalculators.calculateBom(
      moduleCount: v['moduleCount']!.round(), moduleWidthM: v['moduleWidthM']!, modulePowerW: v['modulePowerW']!,
      inverterSizeKw: v['inverterSizeKw']!, dcCableLengthM: v['dcCableLengthM']!, acCableLengthM: v['acCableLengthM']!,
      moduleRate: v['moduleRate']!, inverterRate: v['inverterRate']!, railRatePerM: v['railRatePerM']!,
      clampRate: v['clampRate']!, cableRatePerM: v['cableRatePerM']!, earthingAllowance: v['earthingAllowance']!,
    );
    final total = lines.fold<double>(0, (sum, line) => sum + line.amount);
    return EngineeringResult(title: 'Preliminary material estimate', status: 'BUDGET ESTIMATE', metrics: [
      ...lines.map((line) => EngineeringMetric(line.name, '${line.quantity.toStringAsFixed(line.quantity % 1 == 0 ? 0 : 1)} ${line.unit} · ${_inr(line.amount)}')),
      EngineeringMetric('Estimated material total', _inr(total)),
    ], notes: lines.map((line) => '${line.name}: ${line.basis}').where((s) => s.contains(': ')).toList());
  },
);

class _CalculationTab extends StatefulWidget {
  const _CalculationTab({super.key, required this.project, required this.section, required this.initialData, required this.definition, required this.onSave, this.onNext, this.allowManualPlacement = false});
  final SolarProject project;
  final String section;
  final Map<String, Object?> initialData;
  final _ModuleDefinition definition;
  final Future<void> Function(SolarProject, String, Map<String, Object?>) onSave;
  final VoidCallback? onNext;
  final bool allowManualPlacement;

  @override
  State<_CalculationTab> createState() => _CalculationTabState();
}

class _CalculationTabState extends State<_CalculationTab> {
  late final Map<String, TextEditingController> _controllers;
  Set<int> _excluded = {};
  bool _busy = false;
  bool _hasLocalChanges = false;

  @override
  void initState() {
    super.initState();
    _controllers = {for (final field in widget.definition.fields)
      field.key: TextEditingController(text: (widget.initialData[field.key] ?? field.initial).toString())};
    final raw = widget.initialData['manualExcludedCells'];
    if (raw is List) _excluded = raw.whereType<num>().map((n) => n.toInt()).toSet();
  }

  @override
  void didUpdateWidget(covariant _CalculationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasLocalChanges && oldWidget.project.updatedAt != widget.project.updatedAt) {
      for (final field in widget.definition.fields) {
        final nextValue = widget.initialData[field.key] ?? field.initial;
        _controllers[field.key]!.text = nextValue.toString();
      }
      final raw = widget.initialData['manualExcludedCells'];
      _excluded = raw is List ? raw.whereType<num>().map((n) => n.toInt()).toSet() : {};
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }

  Map<String, double> get _values => {
    for (final field in widget.definition.fields)
      field.key: double.tryParse(_controllers[field.key]!.text.trim()) ?? double.nan,
  };

  Map<String, Object?> _snapshot() {
    final values = _values;
    final snapshot = <String, Object?>{
      for (final entry in values.entries) entry.key: entry.value,
      if (widget.allowManualPlacement) 'manualExcludedCells': _excluded.toList()..sort(),
      'needsReview': false,
    };
    try {
      final result = widget.definition.calculate(values, _excluded.toList());
      snapshot['calculationResult'] = <String, Object?>{
        'title': result.title,
        'status': result.status,
        'moduleCount': result.moduleCount,
        'rows': result.rows,
        'columns': result.columns,
        'panelLengthM': result.panelLengthM,
        'panelWidthM': result.panelWidthM,
        'metrics': result.metrics.map((metric) => <String, Object?>{
          'label': metric.label, 'value': metric.value, 'unit': metric.unit,
        }).toList(),
        'warnings': result.warnings,
        'assumptions': result.notes,
      };
    } catch (_) {
      snapshot.remove('calculationResult');
    }
    return snapshot;
  }

  Future<bool> _save() async {
    final values = _values;
    final invalid = <String>[];
    for (final field in widget.definition.fields) {
      final value = values[field.key]!;
      if (!value.isFinite || (field.min != null && value < field.min!) || (field.max != null && value > field.max!)) {
        invalid.add(field.label);
      }
    }
    for (final key in const ['moduleCount', 'modulesPerString', 'stringCount']) {
      final value = values[key];
      if (value != null && value.isFinite && value != value.roundToDouble()) invalid.add(key);
    }
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correct these inputs before saving: ${invalid.join(', ')}')),
      );
      return false;
    }
    try {
      // Cross-field/geometry validation is performed by the same pure
      // calculator used for the live result; invalid designs cannot be saved.
      widget.definition.calculate(values, _excluded.toList());
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot save this design: $error')));
      return false;
    }
    setState(() => _busy = true);
    var saved = false;
    try {
      await widget.onSave(widget.project, widget.section, _snapshot());
      if (mounted) setState(() => _hasLocalChanges = false);
      saved = true;
    } catch (_) {
      // The save handler has already surfaced the storage error.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return saved;
  }

  void _toggleCell(int index) {
    setState(() {
      _hasLocalChanges = true;
      if (_excluded.contains(index)) { _excluded.remove(index); } else { _excluded.add(index); }
    });
    final valid = _values.values.every((value) => value.isFinite) &&
        widget.definition.fields.every((field) {
          final value = _values[field.key]!;
          return (field.min == null || value >= field.min!) &&
              (field.max == null || value <= field.max!);
        });
    if (!valid) return; // Keep the cell edit in memory; Save inputs will validate it.
    try {
      widget.definition.calculate(_values, _excluded.toList());
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Manual placement was not saved: $error')));
      return;
    }
    widget.onSave(widget.project, widget.section, _snapshot()).then((_) {
      if (mounted) setState(() => _hasLocalChanges = false);
    }).catchError((Object _) {
      // Save errors are shown by the parent workspace.
    });
  }

  @override
  Widget build(BuildContext context) {
    EngineeringResult? result;
    String? calculationError;
    try {
      result = widget.definition.calculate(_values, _excluded.toList());
    } catch (error) { calculationError = error.toString().replaceFirst('Invalid argument(s): ', ''); }
    final calculatedResult = result;
    final isPv = widget.allowManualPlacement;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeading(title: widget.definition.title),
        const SizedBox(height: 6),
        Text(widget.definition.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (widget.initialData['needsReview'] == true) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFEFD8B2))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF9B681F)), const SizedBox(width: 8), Expanded(child: Text(widget.initialData['reviewReason']?.toString() ?? 'An upstream design input changed. Review the values and save this section again.', style: const TextStyle(fontSize: 12, color: Color(0xFF76582B), height: 1.4)))])),
        ],
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Design inputs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 3 : constraints.maxWidth > 440 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 9, mainAxisExtent: 76),
              itemCount: widget.definition.fields.length,
              itemBuilder: (context, index) {
                final f = widget.definition.fields[index];
                return TextField(
                  controller: _controllers[f.key],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => setState(() {
                    _hasLocalChanges = true;
                    if (widget.allowManualPlacement && const {
                      'roofLengthM', 'roofWidthM', 'moduleLengthM', 'moduleWidthM',
                      'edgeSetbackM', 'walkwayWidthM', 'moduleGapM',
                    }.contains(f.key)) {
                      // Cell indexes are geometry-specific. Clear old exclusions
                      // as soon as the grid geometry changes so the same index
                      // cannot silently refer to a different physical panel.
                      _excluded.clear();
                    }
                  }),
                  decoration: InputDecoration(labelText: f.label, suffixText: f.unit, helperText: f.help, isDense: true),
                );
              },
            );
          }),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (widget.onNext != null) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : () async { if (await _save()) widget.onNext!.call(); },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Save & continue'),
              ),
              const SizedBox(width: 9),
            ],
            FilledButton.icon(onPressed: _busy ? null : () => _save(), icon: const Icon(Icons.save_outlined), label: Text(_busy ? 'Saving…' : 'Save inputs')),
          ]),
        ]))),
        const SizedBox(height: 14),
        if (calculationError != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Icon(Icons.error_outline), const SizedBox(width: 10), Expanded(child: Text(calculationError))]))),
        if (calculatedResult != null) ...[
          Row(children: [Expanded(child: SectionHeading(title: 'Calculation result')), Chip(label: Text(calculatedResult.status))]),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 760 ? 3 : constraints.maxWidth > 490 ? 2 : 1;
            return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 86),
              itemCount: calculatedResult.metrics.length,
              itemBuilder: (context, index) => _MetricTile(metric: calculatedResult.metrics[index]),
            );
          }),
          if (widget.section == 'yield' && calculatedResult.metrics.isNotEmpty) ...[
            const SizedBox(height: 18),
            _MonthlyYieldChart(annualKwh: double.tryParse(calculatedResult.metrics.first.value) ?? 0),
          ],
          if (widget.section == 'battery' && calculatedResult.metrics.length > 1) ...[
            const SizedBox(height: 18),
            _BatteryEnergyVisual(usableKwh: double.tryParse(calculatedResult.metrics[0].value) ?? 0, nominalKwh: double.tryParse(calculatedResult.metrics[1].value) ?? 0),
          ],
          if (isPv && calculatedResult.moduleCount > 0) ...[
            const SizedBox(height: 18),
            const SectionHeading(title: 'Manual module placement'),
            const SizedBox(height: 4),
            const Text('Tap a module cell to exclude or restore it. This edits the rectangular grid; it is not a polygon/obstacle CAD editor.'),
            const SizedBox(height: 8),
            _ManualPlacementGrid(columns: calculatedResult.columns, rows: calculatedResult.rows, excluded: _excluded, onTap: _toggleCell),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.check_box, size: 17), const SizedBox(width: 6), Text('${calculatedResult.moduleCount} panels retained · ${_excluded.length} cells excluded')]),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () async {
              final v = _values;
              try {
                final dxf = SolarCalculators.createDxf(roofLengthM: v['roofLengthM']!, roofWidthM: v['roofWidthM']!, rows: calculatedResult.rows, columns: calculatedResult.columns,
                  panelLengthM: calculatedResult.panelLengthM, panelWidthM: calculatedResult.panelWidthM, edgeSetbackM: v['edgeSetbackM']!, walkwayWidthM: v['walkwayWidthM']!, moduleGapM: v['moduleGapM']!, excludedCells: _excluded);
                await FileSaver.instance.saveFile(name: 'gensolar-pv-layout-${DateTime.now().millisecondsSinceEpoch}', bytes: Uint8List.fromList(utf8.encode(dxf)), fileExtension: 'dxf', mimeType: MimeType.other);
              } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DXF export failed: $error'))); }
            }, icon: const Icon(Icons.download_outlined), label: const Text('Export PV layout as DXF')),
          ],
          if (calculatedResult.notes.isNotEmpty || calculatedResult.warnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            if (calculatedResult.warnings.isNotEmpty) _NoticeCard(title: 'Review warnings', items: calculatedResult.warnings, warning: true),
            if (calculatedResult.notes.isNotEmpty) _NoticeCard(title: 'Assumptions and scope', items: calculatedResult.notes, warning: false),
          ],
        ],
      ]))),
    );
  }
}

class _MonthlyYieldChart extends StatelessWidget {
  const _MonthlyYieldChart({required this.annualKwh});
  final double annualKwh;
  static const _shares = <double>[.075, .078, .095, .096, .092, .083, .073, .074, .078, .087, .087, .082];
  static const _months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final monthlyAverage = annualKwh / 12;
    final peak = _shares.reduce((a, b) => a > b ? a : b);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Indicative monthly generation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))), Text('${NumberFormat('#,##0').format(monthlyAverage)} kWh avg.', style: const TextStyle(fontSize: 11, color: GenSolarTheme.brandGreen, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 5),
      Text('Illustrative seasonal allocation of the annual estimate. Replace with source-backed monthly resource data for project finance.', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16),
      SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(12, (index) {
        final value = annualKwh * _shares[index];
        return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 8, color: Color(0xFF78867D))),
          const SizedBox(height: 5),
          Expanded(child: Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(heightFactor: _shares[index] / peak, widthFactor: .82, child: DecoratedBox(decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF126B4A), Color(0xFF70B996)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(6))))))),
          const SizedBox(height: 6), Text(_months[index], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF66756C))),
        ])));
      }))),
      const Divider(height: 20),
      Row(children: [const Icon(Icons.bolt_rounded, size: 17, color: GenSolarTheme.brandGreen), const SizedBox(width: 7), Text('Annual estimate ${NumberFormat('#,##0').format(annualKwh)} kWh', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))]),
    ])));
  }
}

class _BatteryEnergyVisual extends StatelessWidget {
  const _BatteryEnergyVisual({required this.usableKwh, required this.nominalKwh});
  final double usableKwh;
  final double nominalKwh;

  @override
  Widget build(BuildContext context) {
    final ratio = nominalKwh <= 0 ? 0.0 : (usableKwh / nominalKwh).clamp(0.0, 1.0).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Battery energy reserve', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 13),
      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 18, child: Row(children: [
        Expanded(flex: (ratio * 1000).round().clamp(1, 1000).toInt(), child: Container(color: const Color(0xFF21865A))),
        if (ratio < 1) Expanded(flex: ((1 - ratio) * 1000).round().clamp(1, 1000).toInt(), child: Container(color: const Color(0xFFE7EFE9))),
      ]))),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: Text('Usable energy · ${usableKwh.toStringAsFixed(2)} kWh', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), Text('Nominal ${nominalKwh.toStringAsFixed(2)} kWh', style: const TextStyle(fontSize: 11, color: Color(0xFF66756C)))]),
      const SizedBox(height: 6),
      Text('The shaded reserve represents energy unavailable under the selected DoD and efficiency assumptions.', style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final EngineeringMetric metric;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(metric.value, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 3), Text('${metric.label}${metric.unit.isEmpty ? '' : ' · ${metric.unit}'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ])));
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.title, required this.items, required this.warning});
  final String title; final List<String> items; final bool warning;
  @override
  Widget build(BuildContext context) => Card(color: warning ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: .45) : Theme.of(context).colorScheme.surfaceContainerLow, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 6), ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(warning ? Icons.warning_amber_rounded : Icons.info_outline, size: 17), const SizedBox(width: 8), Expanded(child: Text(item, style: Theme.of(context).textTheme.bodySmall))])))])));
}

class _ManualPlacementGrid extends StatelessWidget {
  const _ManualPlacementGrid({required this.columns, required this.rows, required this.excluded, required this.onTap});
  final int columns, rows; final Set<int> excluded; final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    final shownColumns = columns.clamp(1, 12).toInt();
    final total = (columns * rows).clamp(0, 120).toInt();
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Roof grid preview · $rows × $columns positions', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: total,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: shownColumns, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1.5),
        itemBuilder: (context, index) {
          final off = excluded.contains(index);
          return InkWell(onTap: () => onTap(index), borderRadius: BorderRadius.circular(5), child: Container(
            decoration: BoxDecoration(color: off ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(5)),
            child: Icon(off ? Icons.block : Icons.solar_power, size: 16, color: off ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
          ));
        }),
      if (columns * rows > total) Text('Preview limited to the first $total cells. Full large-format layout editing is not included.', style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}

class _DeliveryTab extends StatefulWidget {
  const _DeliveryTab({super.key, required this.project, required this.initialData, required this.procurementData, required this.onSave, this.onNext});
  final SolarProject project;
  final Map<String, Object?> initialData;
  final Map<String, Object?> procurementData;
  final Future<void> Function(SolarProject, String, Map<String, Object?>) onSave;
  final VoidCallback? onNext;
  @override
  State<_DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends State<_DeliveryTab> {
  static const constructionTasks = [
    'Approved-for-construction drawings available', 'Material quantities and specifications checked', 'Roof condition and access inspected',
    'Mounting structure material received and inspected', 'Structure installation and torque records complete', 'PV modules and inverters installed',
    'DC and AC cable routing inspected', 'Labels, barriers and safety signage installed',
  ];
  static const commissioningTasks = [
    'Visual inspection and equipment nameplate record', 'Module string polarity and continuity checked',
    'Insulation resistance tests recorded', 'Earth continuity and earth resistance recorded', 'Open-circuit string voltage and current recorded',
    'Inverter configuration and protection settings checked', 'Grid synchronization / anti-islanding witnessed', 'Monitoring portal and data logger commissioned',
    'Customer training, warranties and handover completed',
  ];
  late Map<String, List<bool>> _checks;
  late final TextEditingController _vendor;
  late final TextEditingController _contact;
  late final TextEditingController _poNumber;
  late final TextEditingController _poAmount;
  late final TextEditingController _expectedDate;
  String _poStatus = 'Draft';
  bool _savingProcurement = false;

  @override
  void initState() {
    super.initState();
    _checks = {
      'construction': _readChecks('construction', constructionTasks.length),
      'commissioning': _readChecks('commissioning', commissioningTasks.length),
    };
    _vendor = TextEditingController(text: widget.procurementData['vendor']?.toString() ?? '');
    _contact = TextEditingController(text: widget.procurementData['contact']?.toString() ?? '');
    _poNumber = TextEditingController(text: widget.procurementData['poNumber']?.toString() ?? '');
    _poAmount = TextEditingController(text: widget.procurementData['poAmount']?.toString() ?? '0');
    _expectedDate = TextEditingController(text: widget.procurementData['expectedDate']?.toString() ?? '');
    const validStatuses = ['Draft', 'RFQ sent', 'Quotation received', 'Approved', 'Ordered', 'Partially received', 'Received', 'Closed'];
    final savedStatus = widget.procurementData['status']?.toString() ?? 'Draft';
    _poStatus = validStatuses.contains(savedStatus) ? savedStatus : 'Draft';
  }

  @override
  void dispose() {
    _vendor.dispose(); _contact.dispose(); _poNumber.dispose(); _poAmount.dispose(); _expectedDate.dispose();
    super.dispose();
  }

  List<bool> _readChecks(String key, int count) {
    final raw = widget.initialData[key];
    if (raw is List) return List<bool>.generate(count, (i) => i < raw.length && raw[i] == true);
    return List<bool>.filled(count, false);
  }

  Future<void> _toggle(String group, int index, bool checked) async {
    final previous = _checks[group]![index];
    setState(() => _checks[group]![index] = checked);
    try {
      await widget.onSave(widget.project, 'delivery', _checks.map((k, v) => MapEntry<String, Object?>(k, List<bool>.from(v))));
    } catch (_) {
      if (mounted) setState(() => _checks[group]![index] = previous);
    }
  }

  Future<void> _saveProcurement() async {
    final amount = double.tryParse(_poAmount.text.trim());
    final deliveryDate = _expectedDate.text.trim();
    final validDate = deliveryDate.isEmpty || DateTime.tryParse(deliveryDate) != null;
    if (_vendor.text.trim().isEmpty || _poNumber.text.trim().isEmpty || amount == null || !amount.isFinite || amount < 0 || !validDate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a supplier, PO / RFQ reference, a valid non-negative amount and a valid YYYY-MM-DD delivery date.')));
      return;
    }
    setState(() => _savingProcurement = true);
    try {
      await widget.onSave(widget.project, 'procurement', <String, Object?>{
        'vendor': _vendor.text.trim(),
        'contact': _contact.text.trim(),
        'poNumber': _poNumber.text.trim(),
        'poAmount': amount,
        'expectedDate': _expectedDate.text.trim(),
        'status': _poStatus,
      });
    } catch (_) {
      // The workspace save handler has surfaced the error.
    } finally {
      if (mounted) setState(() => _savingProcurement = false);
    }
  }

  Widget _group(String key, String title, List<String> tasks) {
    final done = _checks[key]!.where((v) => v).length;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))), Text('$done / ${tasks.length}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 9), SizedBox(width: 110, child: LinearProgressIndicator(value: done / tasks.length, minHeight: 7))]),
      const Divider(height: 20),
      ...List.generate(tasks.length, (i) => CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, value: _checks[key]![i], title: Text(tasks[i], style: const TextStyle(fontSize: 13)), onChanged: (value) => _toggle(key, i, value ?? false))),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final done = _checks.values.fold<int>(0, (sum, list) => sum + list.where((v) => v).length);
    final total = constructionTasks.length + commissioningTasks.length;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 32), children: [
      const SectionHeading(title: 'Procurement, construction & commissioning', subtitle: 'Track purchasing and the site execution checklist in the same EPC project.'),
      if (widget.initialData['needsReview'] == true) ...[
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(13)), child: Text(widget.initialData['reviewReason']?.toString() ?? 'Upstream procurement inputs changed. Review project delivery records.', style: const TextStyle(color: Color(0xFF76582B), fontSize: 12))),
      ],
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: Text('Site execution checks completed', style: Theme.of(context).textTheme.bodySmall)),
        Text('$done / $total', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF176B4A))),
      ]),
      const SizedBox(height: 7),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 8)),
      const SizedBox(height: 15),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.local_shipping_rounded, color: Color(0xFF176B4A)), const SizedBox(width: 9), Expanded(child: Text('Supplier / purchase order register', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))), Chip(label: Text(_poStatus))]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 660 ? 2 : 1;
          return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 4, childAspectRatio: columns == 1 ? 5.0 : 4.2, children: [
            TextField(controller: _vendor, decoration: const InputDecoration(labelText: 'Supplier / vendor *')),
            TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact / email / phone')),
            TextField(controller: _poNumber, decoration: const InputDecoration(labelText: 'RFQ / PO reference *')),
            TextField(controller: _poAmount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Order / quotation amount', prefixText: '₹ ')),
            TextField(controller: _expectedDate, decoration: const InputDecoration(labelText: 'Expected delivery (YYYY-MM-DD)', prefixIcon: Icon(Icons.event_outlined))),
            DropdownButtonFormField<String>(initialValue: _poStatus, decoration: const InputDecoration(labelText: 'Procurement status'), items: const ['Draft', 'RFQ sent', 'Quotation received', 'Approved', 'Ordered', 'Partially received', 'Received', 'Closed'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) { if (value != null) setState(() => _poStatus = value); }),
          ]);
        }),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _savingProcurement ? null : _saveProcurement, icon: const Icon(Icons.save_outlined), label: Text(_savingProcurement ? 'Saving…' : 'Save procurement record'))),
        const SizedBox(height: 6),
        Text('This is a single primary supplier / PO record, not a full multi-vendor RFQ and goods-receipt ledger.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]))),
      const SizedBox(height: 14),
      _group('construction', 'Construction quality checklist', constructionTasks),
      const SizedBox(height: 12),
      _group('commissioning', 'Commissioning & handover checklist', commissioningTasks),
      const SizedBox(height: 12),
      if (widget.procurementData['needsReview'] == true) ...[
        const SizedBox(height: 10),
        const _NoticeCard(title: 'Procurement review required', items: ['The BOM or quantities changed after the supplier / purchase-order record. Confirm the vendor quotation, amount and order status before continuing.'], warning: true),
      ],
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerRight, child: FilledButton.icon(
        onPressed: widget.onNext,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continue to CAD plan'),
      )),
      const SizedBox(height: 12),
      const _NoticeCard(title: 'Evidence and release gate', items: ['Attach and retain approved drawings, inspection reports, test sheets and equipment datasheets outside this checklist register.', 'A checked item records user confirmation only; it does not validate the underlying work or measurements.', 'Final energization, utility interconnection and customer handover require the relevant qualified-person sign-offs.'], warning: true),
    ]);
  }
}

class _CadTab extends StatelessWidget {
  const _CadTab({super.key, required this.project, required this.onSave, required this.onReviewPv, this.onNext});
  final SolarProject project;
  final Future<void> Function(Map<String, Object?>) onSave;
  final VoidCallback onReviewPv;
  final VoidCallback? onNext;
  Map<String, Object?> _map(String key) { final v = project.engineeringData[key]; return v is Map ? Map<String, Object?>.from(v) : {}; }
  @override
  Widget build(BuildContext context) {
    final pv = _map('pv');
    final number = <String, double>{for (final e in pv.entries) if (e.value is num) e.key: (e.value as num).toDouble()};
    if (pv.isEmpty || pv['calculationResult'] is! Map) {
      return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.grid_on_rounded, size: 42),
        const SizedBox(height: 12),
        Text('Save a PV layout before opening CAD', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('The CAD plan is generated from the active project’s saved PV grid. Enter the site dimensions and module layout first.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onReviewPv, icon: const Icon(Icons.solar_power_outlined), label: const Text('Open PV layout')),
      ])))));
    }
    final pvNeedsReview = pv['needsReview'] == true;
    try {
      final result = SolarCalculators.calculateRectangularPvLayout(
        roofLengthM: number['roofLengthM'] ?? 30, roofWidthM: number['roofWidthM'] ?? 20,
        modulePowerW: number['modulePowerW'] ?? 550, moduleLengthM: number['moduleLengthM'] ?? 2.278,
        moduleWidthM: number['moduleWidthM'] ?? 1.134, edgeSetbackM: number['edgeSetbackM'] ?? .5,
        walkwayWidthM: number['walkwayWidthM'] ?? 1, moduleGapM: number['moduleGapM'] ?? .03,
        targetCapacityKw: number['targetCapacityKw'] ?? 10,
        excludedCellIndexes: (pv['manualExcludedCells'] is List ? (pv['manualExcludedCells'] as List).whereType<num>().map((n) => n.toInt()).toList() : const []),
      );
      return ListView(padding: const EdgeInsets.all(18), children: [
        const SectionHeading(title: '2D roof plan & CAD exchange'),
        const Text('A scaled rectangular concept view and DXF export are generated from the active project PV grid. This is not a full editable CAD system or a certified fabrication drawing.'),
        if (pvNeedsReview) ...[
          const SizedBox(height: 10),
          const _NoticeCard(title: 'PV layout changed upstream', items: ['This CAD preview is based on an older saved PV layout. Review and save the PV layout before exporting a new drawing.'], warning: true),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: onReviewPv, icon: const Icon(Icons.refresh_rounded), label: const Text('Review PV layout'))),
        ],
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(height: 280, child: CustomPaint(painter: _RoofPlanPainter(
          roofLength: number['roofLengthM'] ?? 30, roofWidth: number['roofWidthM'] ?? 20,
          rows: result.rows, columns: result.columns, panelLength: result.panelLengthM, panelWidth: result.panelWidthM,
          moduleGap: number['moduleGapM'] ?? .03,
          setback: number['edgeSetbackM'] ?? .5, walkway: number['walkwayWidthM'] ?? 1,
          excluded: (pv['manualExcludedCells'] is List ? (pv['manualExcludedCells'] as List).whereType<num>().map((n) => n.toInt()).toSet() : <int>{}),
          color: Theme.of(context).colorScheme.primary,
          outlineColor: Theme.of(context).colorScheme.outline,
        ))))),
        const SizedBox(height: 16),
        const SectionHeading(title: 'Isometric site preview', subtitle: 'A conceptual roof and module massing view derived from the same PV layout inputs.'),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(height: 290, child: CustomPaint(painter: _IsometricRoofPainter(
          roofLength: number['roofLengthM'] ?? 30,
          roofWidth: number['roofWidthM'] ?? 20,
          rows: result.rows,
          columns: result.columns,
          panelLength: result.panelLengthM,
          panelWidth: result.panelWidthM,
          moduleGap: number['moduleGapM'] ?? .03,
          setback: number['edgeSetbackM'] ?? .5,
          walkway: number['walkwayWidthM'] ?? 1,
          excluded: (pv['manualExcludedCells'] is List ? (pv['manualExcludedCells'] as List).whereType<num>().map((n) => n.toInt()).toSet() : <int>{}),
          panelColor: Theme.of(context).colorScheme.primary,
        ))))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [Chip(label: Text('Roof ${((number['roofLengthM'] ?? 30) * (number['roofWidthM'] ?? 20)).toStringAsFixed(1)} m²')), Chip(label: Text('${result.moduleCount} modules')), Chip(label: Text('${result.columns} columns × ${result.rows} rows'))]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: pvNeedsReview ? null : () async {
          try {
            final dxf = SolarCalculators.createDxf(roofLengthM: number['roofLengthM'] ?? 30, roofWidthM: number['roofWidthM'] ?? 20,
              rows: result.rows, columns: result.columns, panelLengthM: result.panelLengthM, panelWidthM: result.panelWidthM,
              moduleGapM: number['moduleGapM'] ?? .03, edgeSetbackM: number['edgeSetbackM'] ?? .5, walkwayWidthM: number['walkwayWidthM'] ?? 1,
              excludedCells: (pv['manualExcludedCells'] is List ? (pv['manualExcludedCells'] as List).whereType<num>().map((n) => n.toInt()).toSet() : <int>{}));
            await FileSaver.instance.saveFile(name: '${_safeName(project.name)}-pv-plan', bytes: Uint8List.fromList(utf8.encode(dxf)), fileExtension: 'dxf', mimeType: MimeType.other);
            await onSave({
              'drawingType': 'Rectangular PV roof plan DXF',
              'fileExtension': 'dxf',
              'layoutModuleCount': result.moduleCount,
              'layoutRows': result.rows,
              'layoutColumns': result.columns,
              'exportedAtUtc': DateTime.now().toUtc().toIso8601String(),
            });
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DXF drawing exported and CAD stage recorded.')));
          } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export or CAD record failed: $error'))); }
        }, icon: const Icon(Icons.download), label: const Text('Download DXF drawing')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: pvNeedsReview ? null : () async {
          try {
            final text = SolarCalculators.createDxf(roofLengthM: number['roofLengthM'] ?? 30, roofWidthM: number['roofWidthM'] ?? 20,
              rows: result.rows, columns: result.columns, panelLengthM: result.panelLengthM, panelWidthM: result.panelWidthM,
              moduleGapM: number['moduleGapM'] ?? .03, edgeSetbackM: number['edgeSetbackM'] ?? .5, walkwayWidthM: number['walkwayWidthM'] ?? 1,
              excludedCells: (pv['manualExcludedCells'] is List ? (pv['manualExcludedCells'] as List).whereType<num>().map((n) => n.toInt()).toSet() : <int>{}));
            await ClipboardService.copy(text);
            await onSave({
              'drawingType': 'Rectangular PV roof plan DXF text',
              'fileExtension': 'dxf',
              'layoutModuleCount': result.moduleCount,
              'layoutRows': result.rows,
              'layoutColumns': result.columns,
              'exportedAtUtc': DateTime.now().toUtc().toIso8601String(),
            });
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DXF text copied and CAD stage recorded.')));
          } catch (error) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DXF copy failed: $error')));
          }
        }, icon: const Icon(Icons.copy), label: const Text('Copy DXF text')),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: pvNeedsReview
            ? OutlinedButton.icon(onPressed: onReviewPv, icon: const Icon(Icons.refresh_rounded), label: const Text('Review PV before DPR'))
            : FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.description_outlined), label: const Text('Continue to DPR'))),
        const SizedBox(height: 8),
        const _NoticeCard(title: 'CAD limitations', items: ['Rectangular roof and regular grid only.', 'No DWG/SKP import, geometry editing, dimensions, layers panel, cable routing or full 3D scene.', 'Confirm drawing units, edge margins, module clamp zones and walkways before using the DXF as a design reference.'], warning: true),
      ]);
    } catch (error) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Enter valid PV layout inputs before creating a CAD view. $error')));
    }
  }
}

class ClipboardService {
  static Future<void> copy(String value) async { await Clipboard.setData(ClipboardData(text: value)); }
}

class _RoofPlanPainter extends CustomPainter {
  _RoofPlanPainter({required this.roofLength, required this.roofWidth, required this.rows, required this.columns,
    required this.panelLength, required this.panelWidth, required this.moduleGap, required this.setback, required this.walkway,
    required this.excluded, required this.color, required this.outlineColor});
  final double roofLength, roofWidth, panelLength, panelWidth, moduleGap, setback, walkway;
  final int rows, columns;
  final Set<int> excluded;
  final Color color, outlineColor;

  void _label(Canvas canvas, String text, Offset offset, {Color color = const Color(0xFF627268), double size = 10, FontWeight weight = FontWeight.w700}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'Roboto')),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _dimension(Canvas canvas, Offset start, Offset end, String label, {bool horizontal = true}) {
    final line = Paint()..color = outlineColor.withValues(alpha: .75)..strokeWidth = 1;
    canvas.drawLine(start, end, line);
    const arrow = 5.0;
    if (horizontal) {
      canvas.drawLine(start, start + const Offset(arrow, -3), line);
      canvas.drawLine(start, start + const Offset(arrow, 3), line);
      canvas.drawLine(end, end + const Offset(-arrow, -3), line);
      canvas.drawLine(end, end + const Offset(-arrow, 3), line);
      final width = label.length * 6.2;
      _label(canvas, label, Offset((start.dx + end.dx - width) / 2, start.dy - 15), size: 9);
    } else {
      canvas.drawLine(start, start + const Offset(-3, arrow), line);
      canvas.drawLine(start, start + const Offset(3, arrow), line);
      canvas.drawLine(end, end + const Offset(-3, -arrow), line);
      canvas.drawLine(end, end + const Offset(3, -arrow), line);
      _label(canvas, label, Offset(start.dx + 7, (start.dy + end.dy) / 2 - 5), size: 9);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (roofLength <= 0 || roofWidth <= 0 || size.width <= 0 || size.height <= 0) return;
    final scale = math.min((size.width - 104) / roofLength, (size.height - 90) / roofWidth).clamp(.1, 10000).toDouble();
    final w = roofLength * scale;
    final h = roofWidth * scale;
    final left = (size.width - w) / 2;
    final top = 28.0 + (size.height - 84 - h) / 2;
    final roof = Rect.fromLTWH(left, top, w, h);

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFBFCFB));
    final roofFill = Paint()..color = const Color(0xFFEAF0EC);
    final roofStroke = Paint()..color = outlineColor..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(roof, const Radius.circular(5)), Paint()..color = roofFill.color);
    canvas.drawRRect(RRect.fromRectAndRadius(roof, const Radius.circular(5)), roofStroke);

    // Subtle drafting grid inside the roof boundary.
    final gridPaint = Paint()..color = outlineColor.withValues(alpha: .10)..strokeWidth = .55;
    for (var i = 1; i < 10; i++) {
      final x = left + w * i / 10;
      final y = top + h * i / 10;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), gridPaint);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gridPaint);
    }

    // Perimeter setback zone.
    final inner = Rect.fromLTWH(left + setback * scale, top + setback * scale,
        math.max(0.0, roofLength - setback * 2).toDouble() * scale, math.max(0.0, roofWidth - setback * 2).toDouble() * scale);
    final setbackPaint = Paint()..color = const Color(0xFFE9B95F).withValues(alpha: .12);
    canvas.drawRect(roof, setbackPaint);
    canvas.drawRect(inner, Paint()..color = const Color(0xFFE7F1EA));

    // Access walkway with a hatch pattern.
    final walkwayRect = Rect.fromLTWH(left + setback * scale, top + setback * scale,
        math.max(0.0, roofLength - setback * 2).toDouble() * scale, math.min(walkway, math.max(0.0, roofWidth - setback * 2)).toDouble() * scale);
    canvas.drawRect(walkwayRect, Paint()..color = const Color(0xFFFFE9C8));
    final hatch = Paint()..color = const Color(0xFFC38A36).withValues(alpha: .4)..strokeWidth = .7;
    for (var x = walkwayRect.left - walkwayRect.height; x < walkwayRect.right; x += 10) {
      final x1 = math.max(walkwayRect.left, x).toDouble();
      final y1 = walkwayRect.bottom - (x1 - x);
      final x2 = math.min(walkwayRect.right, x + walkwayRect.height).toDouble();
      final y2 = walkwayRect.bottom - (x2 - x);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), hatch);
    }
    _label(canvas, 'ACCESS WALKWAY', Offset(walkwayRect.left + 5, walkwayRect.top + 4), color: const Color(0xFF93631F), size: 7.5);

    // PV module fields.
    for (var row = 0; row < rows && row < 60; row++) {
      for (var col = 0; col < columns && col < 60; col++) {
        final index = row * columns + col;
        final rect = Rect.fromLTWH(
          left + (setback + row * (panelLength + moduleGap)) * scale,
          top + (setback + walkway + col * (panelWidth + moduleGap)) * scale,
          panelLength * scale,
          panelWidth * scale,
        );
        if (!inner.contains(rect.topLeft) || !inner.contains(rect.bottomRight)) continue;
        final blocked = excluded.contains(index);
        final fill = Paint()..color = blocked ? const Color(0xFFFCE8E6) : color.withValues(alpha: .23);
        final stroke = Paint()
          ..color = blocked ? const Color(0xFFC94B43) : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), stroke);
        if (blocked) {
          final cross = Paint()..color = const Color(0xFFC94B43)..strokeWidth = 1.2;
          canvas.drawLine(rect.topLeft, rect.bottomRight, cross);
          canvas.drawLine(rect.topRight, rect.bottomLeft, cross);
        } else if (rect.width > 13 && rect.height > 10) {
          final cellLine = Paint()..color = color.withValues(alpha: .32)..strokeWidth = .65;
          canvas.drawLine(Offset(rect.left + rect.width / 2, rect.top + 1), Offset(rect.left + rect.width / 2, rect.bottom - 1), cellLine);
          canvas.drawLine(Offset(rect.left + 1, rect.top + rect.height / 2), Offset(rect.right - 1, rect.top + rect.height / 2), cellLine);
        }
      }
    }

    // Dimension strings and north reference.
    _dimension(canvas, Offset(roof.left, roof.bottom + 19), Offset(roof.right, roof.bottom + 19), '${roofLength.toStringAsFixed(2)} m');
    _dimension(canvas, Offset(roof.left - 30, roof.top), Offset(roof.left - 30, roof.bottom), '${roofWidth.toStringAsFixed(2)} m', horizontal: false);
    final north = Offset(roof.right - 20, roof.top - 7);
    final northPaint = Paint()..color = const Color(0xFF287E91)..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    canvas.drawLine(north + const Offset(0, 17), north, northPaint);
    final arrow = Path()..moveTo(north.dx, north.dy - 3)..lineTo(north.dx - 5, north.dy + 5)..lineTo(north.dx + 5, north.dy + 5)..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFF287E91));
    _label(canvas, 'N', north + const Offset(-3, -16), color: const Color(0xFF287E91), size: 9);

    // Compact legend.
    final legendY = size.height - 13;
    canvas.drawRect(Rect.fromLTWH(12, legendY - 8, 9, 7), Paint()..color = color.withValues(alpha: .35));
    _label(canvas, 'PV module', Offset(25, legendY - 10), size: 8.5);
    canvas.drawRect(Rect.fromLTWH(98, legendY - 8, 9, 7), Paint()..color = const Color(0xFFFFE9C8));
    _label(canvas, 'Access', Offset(111, legendY - 10), size: 8.5);
    canvas.drawRect(Rect.fromLTWH(163, legendY - 8, 9, 7), Paint()..color = const Color(0xFFFCE8E6));
    _label(canvas, 'Excluded', Offset(176, legendY - 10), size: 8.5);
    _label(canvas, 'CONCEPT PLAN · NOT FOR CONSTRUCTION', Offset(math.max(10.0, size.width - 228).toDouble(), 3), color: const Color(0xFF849188), size: 7.5);
  }

  @override
  bool shouldRepaint(covariant _RoofPlanPainter old) => old.rows != rows || old.columns != columns || old.excluded != excluded || old.roofLength != roofLength || old.roofWidth != roofWidth || old.moduleGap != moduleGap || old.panelLength != panelLength || old.panelWidth != panelWidth || old.setback != setback || old.walkway != walkway || old.color != color || old.outlineColor != outlineColor;
}

class _IsometricRoofPainter extends CustomPainter {
  _IsometricRoofPainter({required this.roofLength, required this.roofWidth, required this.rows, required this.columns,
    required this.panelLength, required this.panelWidth, required this.moduleGap, required this.setback, required this.walkway,
    required this.excluded, required this.panelColor});
  final double roofLength, roofWidth, panelLength, panelWidth, moduleGap, setback, walkway;
  final int rows, columns;
  final Set<int> excluded;
  final Color panelColor;

  Offset _p(double x, double y, double z, double scale, Offset origin) => Offset(
    origin.dx + (x - y) * scale * .82,
    origin.dy + (x + y) * scale * .38 - z * scale * .78,
  );

  Path _quad(Offset a, Offset b, Offset c, Offset d) => Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..lineTo(d.dx, d.dy)..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (roofLength <= 0 || roofWidth <= 0 || size.isEmpty) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFAFCFA));
    final scale = math.min((size.width - 150) / (roofLength + roofWidth), (size.height - 90) / (roofLength + roofWidth) * 2).clamp(.2, 10000).toDouble();
    final origin = Offset(size.width * .54, size.height * .74);
    final eave = 4.2;
    final p00 = _p(0, 0, eave, scale, origin);
    final p10 = _p(roofLength, 0, eave, scale, origin);
    final p11 = _p(roofLength, roofWidth, eave, scale, origin);
    final p01 = _p(0, roofWidth, eave, scale, origin);
    final g00 = _p(0, 0, 0, scale, origin);
    final g10 = _p(roofLength, 0, 0, scale, origin);
    final g11 = _p(roofLength, roofWidth, 0, scale, origin);
    final g01 = _p(0, roofWidth, 0, scale, origin);
    final edge = Paint()..color = const Color(0xFF687B70)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    canvas.drawPath(_quad(g00, g10, p10, p00), Paint()..color = const Color(0xFFD3DED6));
    canvas.drawPath(_quad(g10, g11, p11, p10), Paint()..color = const Color(0xFFBBCABD));
    canvas.drawPath(_quad(g00, g10, p10, p00), edge);
    canvas.drawPath(_quad(g10, g11, p11, p10), edge);
    canvas.drawPath(_quad(p00, p10, p11, p01), Paint()..color = const Color(0xFFEAF1EC));
    canvas.drawPath(_quad(p00, p10, p11, p01), edge);

    // Roof setback boundary and access route.
    final q00 = _p(setback, setback, eave + .05, scale, origin);
    final q10 = _p(roofLength - setback, setback, eave + .05, scale, origin);
    final q11 = _p(roofLength - setback, roofWidth - setback, eave + .05, scale, origin);
    final q01 = _p(setback, roofWidth - setback, eave + .05, scale, origin);
    final setbackPath = _quad(q00, q10, q11, q01);
    canvas.drawPath(setbackPath, Paint()..color = const Color(0xFFE7B45E).withValues(alpha: .12));
    final walkwayEnd = math.min(roofWidth - setback, setback + walkway).toDouble();
    final w00 = _p(setback, setback, eave + .1, scale, origin);
    final w10 = _p(roofLength - setback, setback, eave + .1, scale, origin);
    final w11 = _p(roofLength - setback, walkwayEnd, eave + .1, scale, origin);
    final w01 = _p(setback, walkwayEnd, eave + .1, scale, origin);
    canvas.drawPath(_quad(w00, w10, w11, w01), Paint()..color = const Color(0xFFFFE6BD));

    // Module positions use the exact same rectangular PV grid and exclusion indexes as 2D.
    for (var row = 0; row < rows && row < 60; row++) {
      for (var col = 0; col < columns && col < 60; col++) {
        final index = row * columns + col;
        final x = setback + row * (panelLength + moduleGap);
        final y = setback + walkway + col * (panelWidth + moduleGap);
        if (x + panelLength > roofLength - setback || y + panelWidth > roofWidth - setback) continue;
        final a = _p(x, y, eave + .13, scale, origin);
        final b = _p(x + panelLength, y, eave + .13, scale, origin);
        final c = _p(x + panelLength, y + panelWidth, eave + .13, scale, origin);
        final d = _p(x, y + panelWidth, eave + .13, scale, origin);
        final blocked = excluded.contains(index);
        final moduleFill = Paint()
          ..color = blocked ? const Color(0xFFF5D7D4) : panelColor.withValues(alpha: .68);
        final moduleOutline = Paint()
          ..color = blocked ? const Color(0xFFC64C43) : const Color(0xFF315E4B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7;
        canvas.drawPath(_quad(a, b, c, d), moduleFill);
        canvas.drawPath(_quad(a, b, c, d), moduleOutline);
        if (blocked) {
          final cross = Paint()..color = const Color(0xFFC64C43)..strokeWidth = 1.1;
          canvas.drawLine(a, c, cross);
          canvas.drawLine(b, d, cross);
        }
      }
    }

    final shadow = Paint()..color = const Color(0xFF20392C).withValues(alpha: .08);
    canvas.drawOval(Rect.fromCenter(center: Offset(origin.dx - 8, origin.dy + 5), width: (roofLength + roofWidth) * scale * .95, height: 15), shadow);
    final tp = TextPainter(text: TextSpan(text: '3D CONCEPT VIEW · NOT A STRUCTURAL MODEL', style: const TextStyle(fontSize: 9, color: Color(0xFF738178), fontWeight: FontWeight.w800, letterSpacing: .7)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(12, 10));
    final legendY = size.height - 16;
    canvas.drawRect(Rect.fromLTWH(14, legendY - 8, 10, 8), Paint()..color = panelColor.withValues(alpha: .68));
    final legend = TextPainter(text: const TextSpan(text: 'PV modules', style: TextStyle(fontSize: 9, color: Color(0xFF64746A))), textDirection: TextDirection.ltr)..layout();
    legend.paint(canvas, Offset(29, legendY - 10));
    canvas.drawRect(Rect.fromLTWH(110, legendY - 8, 10, 8), Paint()..color = const Color(0xFFFFE6BD));
    final access = TextPainter(text: const TextSpan(text: 'Access strip', style: TextStyle(fontSize: 9, color: Color(0xFF64746A))), textDirection: TextDirection.ltr)..layout();
    access.paint(canvas, Offset(125, legendY - 10));
  }

  @override
  bool shouldRepaint(covariant _IsometricRoofPainter old) => old.roofLength != roofLength || old.roofWidth != roofWidth || old.rows != rows || old.columns != columns || old.panelLength != panelLength || old.panelWidth != panelWidth || old.moduleGap != moduleGap || old.setback != setback || old.walkway != walkway || old.excluded != excluded || old.panelColor != panelColor;
}

class _ReportTab extends StatelessWidget {
  const _ReportTab({super.key, required this.project, required this.onSave});
  final SolarProject project;
  final Future<void> Function(Map<String, Object?>) onSave;

  String _reportText() {
    final out = StringBuffer();
    out.writeln('GENSOLAR PRO ENGINEERING — PROJECT REPORT');
    out.writeln('Project: ${project.name}');
    out.writeln('Customer: ${project.customer}');
    out.writeln('Location: ${project.location}');
    out.writeln('Target DC capacity: ${project.targetCapacityKw} kWp');
    out.writeln('Report generated: ${DateTime.now().toIso8601String()}');
    out.writeln('Project updated: ${project.updatedAt.toIso8601String()}');
    final issues = _pendingReportIssues(project);
    out.writeln('Document status: ${issues.isEmpty ? 'CURRENT SNAPSHOT' : 'REVIEW DRAFT'}');
    if (issues.isNotEmpty) out.writeln('Sections requiring attention: ${issues.join(', ')}');
    out.writeln('\nENGINEERING WORKSPACE INPUTS');
    for (final entry in project.engineeringData.entries) {
      out.writeln('\n${entry.key.toUpperCase()}');
      if (entry.value is Map) {
        for (final item in (entry.value as Map).entries) { out.writeln('${item.key}: ${item.value}'); }
      } else { out.writeln(entry.value); }
    }
    out.writeln('\nENGINEERING LIMITATIONS');
    out.writeln('This is a project-input and preliminary-calculation report. It is not an approved DPR, IFC drawing, structural certificate, electrical approval, utility approval or construction release. All design values must be reviewed and signed by qualified professionals.');
    return out.toString();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const SectionHeading(title: 'DPR & project documents'),
    if (_pendingReportIssues(project).isNotEmpty) ...[
      _NoticeCard(title: 'DPR snapshot will be marked REVIEW', items: ['Complete or refresh these required sections before treating the document as current: ${_pendingReportIssues(project).join(', ')}. You can still export a draft snapshot, but it will remain marked for review.'], warning: true),
      const SizedBox(height: 10),
    ],
    const Text('Generate a project snapshot PDF from the current saved workspace values. The PDF includes the project header, entered design values and limitations; it does not replace a complete professionally reviewed DPR.'),
    const SizedBox(height: 14),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(project.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Customer: ${project.customer.isEmpty ? 'Not entered' : project.customer}'),
      Text('Site: ${project.location.isEmpty ? 'Not entered' : project.location}'),
      Text('Target capacity: ${project.targetCapacityKw.toStringAsFixed(2)} kWp'),
      Text('Saved workspace sections: ${project.engineeringData.keys.length}'),
    ]))),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: () async {
      try {
        final doc = pw.Document();
        doc.addPage(pw.MultiPage(build: (context) => [
          pw.Header(level: 0, child: pw.Text('GenSolar Pro Engineering')),
          pw.Text('Project report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Project: ${project.name}'), pw.Text('Customer: ${project.customer}'), pw.Text('Location: ${project.location}'),
          pw.Text('Target capacity: ${project.targetCapacityKw.toStringAsFixed(2)} kWp'),
          pw.Text('Generated: ${DateTime.now().toIso8601String()}'),
          pw.Text('Document status: ${_pendingReportIssues(project).isEmpty ? 'CURRENT SNAPSHOT' : 'REVIEW DRAFT'}'),
          if (_pendingReportIssues(project).isNotEmpty) pw.Text('Sections requiring attention: ${_pendingReportIssues(project).join(', ')}'),
          pw.SizedBox(height: 16),
          ...project.engineeringData.entries.expand((entry) => [
            pw.Header(level: 1, child: pw.Text(entry.key.toUpperCase())),
            if (entry.value is Map) ...((entry.value as Map).entries.map((item) => pw.Bullet(text: '${item.key}: ${item.value}')))
            else pw.Text('${entry.value}'),
          ]),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Engineering limitations')),
          pw.Text('This report is a project input and preliminary calculation snapshot. It is not an approved DPR, IFC drawing, structural certificate, electrical approval, utility approval or construction release. Design calculations, assumptions, standard editions, equipment datasheets and source records must be independently verified and signed by qualified professionals.'),
        ]));
        final bytes = await doc.save();
        await FileSaver.instance.saveFile(name: '${_safeName(project.name)}-DPR-snapshot', bytes: bytes, fileExtension: 'pdf', mimeType: MimeType.pdf);
        await onSave({
          'documentType': 'Project DPR snapshot',
          'fileExtension': 'pdf',
          'snapshotUpdatedAt': project.updatedAt.toUtc().toIso8601String(),
          'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'includedSections': project.engineeringData.keys.toList()..sort(),
          'reviewPendingSections': _pendingReportIssues(project),
          'needsReview': _pendingReportIssues(project).isNotEmpty,
        });
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project PDF exported and DPR stage recorded.')));
      } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF export failed: $error'))); }
    }, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Generate and save PDF snapshot')),
    const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: () async {
      try {
        await FileSaver.instance.saveFile(name: '${_safeName(project.name)}-backup', bytes: Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert({'schemaVersion': 1, 'exportedAt': DateTime.now().toUtc().toIso8601String(), 'projects': [project.toJson()]}))), fileExtension: 'json', mimeType: MimeType.json);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project JSON backup exported.')));
      } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('JSON export failed: $error'))); }
    }, icon: const Icon(Icons.data_object), label: const Text('Export project JSON backup')),
    const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: () async {
      try {
        await ClipboardService.copy(_reportText());
        await onSave({
          'documentType': 'Project report text snapshot',
          'fileExtension': 'text',
          'snapshotUpdatedAt': project.updatedAt.toUtc().toIso8601String(),
          'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'includedSections': project.engineeringData.keys.toList()..sort(),
          'reviewPendingSections': _pendingReportIssues(project),
          'needsReview': _pendingReportIssues(project).isNotEmpty,
        });
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project report copied and DPR stage recorded.')));
      } catch (error) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report copy failed: $error')));
      }
    }, icon: const Icon(Icons.copy), label: const Text('Copy full project report text')),
    const SizedBox(height: 14),
    const _NoticeCard(title: 'Required professional review', items: ['Validate solar resource source and energy model.', 'Validate equipment datasheets, cold Voc, MPPT operating range and conductor sizing.', 'Complete structural actions, load combinations, anchorage, connections and foundations to the applicable codes.', 'Confirm statutory approvals, utility interconnection and site-specific safety requirements.'], warning: true),
  ]);
}

List<String> _pendingReportIssues(SolarProject project) {
  const required = ['survey', 'pv', 'yield', 'electrical', 'structural', 'bom', 'procurement', 'delivery', 'cad'];
  final missing = required.where((key) {
    final value = project.engineeringData[key];
    return value is! Map || value.isEmpty;
  }).map((key) => 'missing $key');
  return {..._pendingReviewSections(project), ...missing}.toList()..sort();
}

List<String> _pendingReviewSections(SolarProject project) => project.engineeringData.entries
    .where((entry) => entry.key != 'report' && entry.value is Map && (entry.value as Map)['needsReview'] == true)
    .map((entry) => entry.key)
    .toList()..sort();

String _safeName(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
String _inr(double value) => 'INR ${NumberFormat('#,##0.00').format(value)}';
double _asDouble(Object? value, double fallback) => value is num ? value.toDouble() : fallback;
