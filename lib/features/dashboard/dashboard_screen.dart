import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/models/solar_project.dart';
import '../../core/providers.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/section_heading.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openWorkspace(WidgetRef ref, int tab) {
    ref.read(activeWorkspaceTabProvider.notifier).select(tab);
    ref.read(appNavigationIndexProvider.notifier).select(3);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final selectedId = ref.watch(activeProjectIdProvider);
    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load your projects: $error'))),
      data: (projects) {
        SolarProject? project;
        for (final item in projects) {
          if (item.id == selectedId) { project = item; break; }
        }
        project ??= projects.isEmpty ? null : projects.first;
        if (project != null && selectedId != project.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activeProjectIdProvider.notifier).select(project!.id);
          });
        }
        final totalCapacity = projects.fold<double>(0, (sum, item) => sum + item.targetCapacityKw);
        final engineeringReadyProjects = projects.where((item) => item.status == 'Engineering ready').length;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _HeroPanel(
                  hasProject: project != null,
                  projectName: project?.name,
                  onOpen: () => project == null
                      ? ref.read(appNavigationIndexProvider.notifier).select(1)
                      : _openWorkspace(ref, 0),
                  onCreate: () => ref.read(appNavigationIndexProvider.notifier).select(1),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth > 950 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 3.3 : 2.15,
                    children: [
                      MetricCard(label: 'Active projects', value: '${projects.length}', icon: Icons.folder_copy_rounded, helper: 'Saved on this device'),
                      MetricCard(label: 'Portfolio capacity', value: '${totalCapacity.toStringAsFixed(1)} kWp', icon: Icons.solar_power_rounded, helper: 'Sum of project targets'),
                      MetricCard(label: 'Engineering ready', value: '$engineeringReadyProjects', icon: Icons.task_alt_rounded, helper: 'Required workflow sections saved and current'),
                      MetricCard(label: 'Workspace mode', value: 'Offline first', icon: Icons.cloud_done_rounded, helper: 'Local project persistence'),
                    ],
                  );
                }),
                const SizedBox(height: 26),
                if (project == null)
                  _NoProjectsPanel(onCreate: () => ref.read(appNavigationIndexProvider.notifier).select(1))
                else ...[
                  _WorkflowPanel(project: project, onOpenStep: (tab) => _openWorkspace(ref, tab)),
                  const SizedBox(height: 24),
                  const SectionHeading(title: 'Continue working', subtitle: 'Choose a workspace. All sections use the selected project record.'),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth > 1050 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
                    final actions = const [
                      _QuickAction('Site survey', 'Location, roof dimensions and access', Icons.location_on_rounded, 0, Color(0xFFE9F3FF), Color(0xFF306CA9)),
                      _QuickAction('PV layout', 'Module arrangement and exclusions', Icons.grid_view_rounded, 1, Color(0xFFE5F5EC), Color(0xFF19734A)),
                      _QuickAction('Electrical', 'Strings, MPPT and DC cable screening', Icons.electrical_services_rounded, 3, Color(0xFFFFF2E3), Color(0xFFAE6A1E)),
                      _QuickAction('BOM & budget', 'Material quantity and cost schedule', Icons.inventory_2_rounded, 6, Color(0xFFF1ECFF), Color(0xFF7155AE)),
                    ];
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: actions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 142),
                      itemBuilder: (context, index) => _QuickActionCard(action: actions[index], onTap: () => _openWorkspace(ref, actions[index].tab)),
                    );
                  }),
                ],
                const SizedBox(height: 26),
                Row(children: [
                  const Expanded(child: SectionHeading(title: 'Recent projects', subtitle: 'Pick up where you left off.')),
                  TextButton.icon(onPressed: () => ref.read(appNavigationIndexProvider.notifier).select(1), icon: const Icon(Icons.arrow_forward, size: 17), label: const Text('All projects')),
                ]),
                const SizedBox(height: 10),
                if (projects.isEmpty)
                  const Text('Your newly created projects will appear here.')
                else
                  ...projects.take(4).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _RecentProjectTile(
                      project: item,
                      selected: item.id == project?.id,
                      onTap: () {
                        ref.read(activeProjectIdProvider.notifier).select(item.id);
                        _openWorkspace(ref, 0);
                      },
                    ),
                  )),
                const SizedBox(height: 12),
                const _SafetyFootnote(),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.hasProject, required this.projectName, required this.onOpen, required this.onCreate});
  final bool hasProject;
  final String? projectName;
  final VoidCallback onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF0C3B2C), Color(0xFF176B4A), Color(0xFF21865A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF0C573A).withValues(alpha: .16), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Stack(children: [
        Positioned(right: -12, top: -48, bottom: -44, width: 500, child: IgnorePointer(child: CustomPaint(painter: _SolarHeroPainter()))),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 222),
            child: LayoutBuilder(builder: (context, constraints) {
              final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white.withValues(alpha: .18))), child: const Text('SOLAR EPC COMMAND CENTRE', style: TextStyle(color: Color(0xFFD1EBDD), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4))),
                const SizedBox(height: 15),
                Text(hasProject ? 'Move your project\nfrom survey to handover.' : 'Plan, design and deliver\nsolar projects in one place.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: constraints.maxWidth < 480 ? 25 : 30, height: 1.12)),
                const SizedBox(height: 9),
                Text(hasProject ? 'Active project · ${projectName ?? ''}' : 'Start with a site, connect your engineering and carry the same data through delivery.', style: const TextStyle(color: Color(0xFFD6E8DE), fontSize: 13, height: 1.45)),
                const SizedBox(height: 18),
                Wrap(spacing: 10, runSpacing: 8, children: [
                  FilledButton.icon(onPressed: onOpen, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: GenSolarTheme.brandDeep, padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13)), icon: Icon(hasProject ? Icons.play_arrow_rounded : Icons.add_rounded), label: Text(hasProject ? 'Continue project' : 'Create first project')),
                  if (hasProject) OutlinedButton.icon(onPressed: onCreate, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: .5)), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13)), icon: const Icon(Icons.add, size: 18), label: const Text('New project')),
                ]),
              ]);
              if (constraints.maxWidth < 620) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 100)]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 18),
                const Expanded(flex: 4, child: SizedBox(height: 185)),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}

class _SolarHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = const Color(0xFFB8F0D0).withValues(alpha: .10);
    canvas.drawCircle(Offset(size.width * .64, size.height * .43), 155, glow);
    final roof = Path()
      ..moveTo(size.width * .12, size.height * .62)
      ..lineTo(size.width * .56, size.height * .25)
      ..lineTo(size.width * .95, size.height * .58)
      ..lineTo(size.width * .93, size.height * .68)
      ..lineTo(size.width * .16, size.height * .72)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFBCEBD0).withValues(alpha: .11));
    final panelFill = Paint()..color = const Color(0xFFB9EBD0).withValues(alpha: .16);
    final panelLine = Paint()..color = const Color(0xFFD7F8E5).withValues(alpha: .38)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 4; c++) {
        final x = size.width * (.29 + c * .145) - r * 10;
        final y = size.height * (.36 + r * .105) + c * 3;
        final rect = Rect.fromLTWH(x, y, size.width * .12, size.height * .09);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), panelFill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), panelLine);
      }
    }
    final sunPaint = Paint()..color = const Color(0xFFFFD77B).withValues(alpha: .9);
    canvas.drawCircle(Offset(size.width * .83, size.height * .2), 24, sunPaint);
    final ray = Paint()..color = const Color(0xFFFFE7AF).withValues(alpha: .65)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * 3.14159265 / 4;
      final center = Offset(size.width * .83, size.height * .2);
      canvas.drawLine(center + Offset(31 * math.cos(a), 31 * math.sin(a)), center + Offset(40 * math.cos(a), 40 * math.sin(a)), ray);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WorkflowPanel extends StatelessWidget {
  const _WorkflowPanel({required this.project, required this.onOpenStep});
  final SolarProject project;
  final ValueChanged<int> onOpenStep;

  static const _steps = <(String, String, IconData)>[
    ('Site survey', 'survey', Icons.location_on_outlined),
    ('PV design', 'pv', Icons.grid_view_rounded),
    ('Solar yield', 'yield', Icons.wb_sunny_outlined),
    ('Electrical', 'electrical', Icons.electrical_services_outlined),
    ('Battery', 'battery', Icons.battery_charging_full_rounded),
    ('Wind review', 'structural', Icons.architecture_outlined),
    ('BOQ', 'bom', Icons.inventory_2_outlined),
    ('Procurement', 'procurement', Icons.local_shipping_outlined),
    ('Site delivery', 'delivery', Icons.construction_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _steps.where((step) => _isComplete(step.$2) && !_needsReview(step.$2)).length;
    final progress = completed / _steps.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Project workflow', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(project.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: GenSolarTheme.brandMint, borderRadius: BorderRadius.circular(30)), child: Text('$completed / ${_steps.length} saved', style: const TextStyle(color: GenSolarTheme.brandDeep, fontWeight: FontWeight.w800, fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: const Color(0xFFEAF0EB), color: GenSolarTheme.brandGreen)),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 580 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9, mainAxisExtent: 82),
              itemBuilder: (context, index) {
                final step = _steps[index];
                final saved = _isComplete(step.$2);
                final stale = _needsReview(step.$2);
                final selected = saved && !stale;
                return Material(
                  color: selected ? const Color(0xFFF0F8F2) : const Color(0xFFF8FAF8),
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    onTap: () => onOpenStep(step.$2 == 'procurement' || step.$2 == 'delivery' ? 7 : index),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(padding: const EdgeInsets.all(11), child: Row(children: [
                      Container(width: 37, height: 37, decoration: BoxDecoration(color: selected ? const Color(0xFFDDF1E4) : const Color(0xFFECEFED), borderRadius: BorderRadius.circular(11)), child: Icon(step.$3, size: 19, color: selected ? GenSolarTheme.brandGreen : const Color(0xFF6B7B71))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(step.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 4), Text(stale ? 'Review required' : saved ? 'Inputs saved' : 'Not started', style: TextStyle(fontSize: 10, color: stale ? const Color(0xFFAF6A1D) : selected ? GenSolarTheme.brandGreen : const Color(0xFF7B887F)))])),
                      Icon(stale ? Icons.refresh_rounded : saved ? Icons.check_circle_rounded : Icons.chevron_right_rounded, size: 18, color: stale ? const Color(0xFFAF6A1D) : selected ? GenSolarTheme.brandGreen : const Color(0xFF9AA69E)),
                    ])),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 9),
          Text('The workflow carries shared inputs between survey, PV design, energy, electrical sizing and material planning. Upstream edits flag affected downstream sections for review.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
        ]),
      ),
    );
  }

  bool _isComplete(String key) {
    final value = project.engineeringData[key];
    return value is Map && value.isNotEmpty;
  }

  bool _needsReview(String key) {
    final value = project.engineeringData[key];
    return value is Map && value['needsReview'] == true;
  }
}

class _QuickAction {
  const _QuickAction(this.title, this.description, this.icon, this.tab, this.tint, this.foreground);
  final String title;
  final String description;
  final IconData icon;
  final int tab;
  final Color tint;
  final Color foreground;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});
  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: action.tint, borderRadius: BorderRadius.circular(14)), child: Icon(action.icon, color: action.foreground, size: 23)),
            const SizedBox(width: 13),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(action.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(action.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)])),
            const Icon(Icons.arrow_forward_rounded, size: 17, color: Color(0xFF8A978F)),
          ])),
        ),
      );
}

class _RecentProjectTile extends StatelessWidget {
  const _RecentProjectTile({required this.project, required this.selected, required this.onTap});
  final SolarProject project;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: selected ? const Color(0xFFF3F9F5) : Colors.white,
        child: ListTile(
          onTap: onTap,
          leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: GenSolarTheme.brandMint, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.solar_power_rounded, color: GenSolarTheme.brandGreen)),
          title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          subtitle: Text([if (project.customer.isNotEmpty) project.customer, if (project.location.isNotEmpty) project.location, DateFormat.yMMMd().format(project.updatedAt)].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${project.targetCapacityKw.toStringAsFixed(1)} kWp', style: const TextStyle(fontWeight: FontWeight.w800, color: GenSolarTheme.brandGreen)), const SizedBox(width: 10), const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA69E))]),
        ),
      );
}

class _NoProjectsPanel extends StatelessWidget {
  const _NoProjectsPanel({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: LayoutBuilder(builder: (context, constraints) {
    final details = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: GenSolarTheme.brandMint, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add_home_work_rounded, size: 28, color: GenSolarTheme.brandGreen)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Start your first solar project', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Create a project record to unlock the connected site survey, PV design and EPC delivery workflow.') ])),
    ]);
    return constraints.maxWidth < 620
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [details, const SizedBox(height: 16), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create project'))])
        : Row(children: [Expanded(child: details), const SizedBox(width: 14), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create project'))]);
  })));
}

class _SafetyFootnote extends StatelessWidget {
  const _SafetyFootnote();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF7E9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF2E3C7))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.verified_user_outlined, color: Color(0xFF9C6A20), size: 19), SizedBox(width: 10), Expanded(child: Text('Engineering calculations are screening tools unless the module explicitly states otherwise. Structural, electrical, statutory and construction release decisions require project-specific verification and qualified professional approval.', style: TextStyle(color: Color(0xFF785A2D), fontSize: 11, height: 1.4)))]));
}
