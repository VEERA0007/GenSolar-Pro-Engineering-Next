import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../shared/widgets/section_heading.dart';
import '../engineering/advanced_engineering_screen.dart';

class _Workspace {
  const _Workspace({required this.title, required this.description, required this.icon, required this.status, this.tab, this.note = ''});
  final String title;
  final String description;
  final IconData icon;
  final String status;
  final int? tab;
  final String note;
}

const _workspaces = <_Workspace>[
  _Workspace(title: 'Site survey & roof zone', description: 'Coordinates, roof dimensions, slope, edge setbacks and access strip.', icon: Icons.location_on_rounded, status: 'Available', tab: 0),
  _Workspace(title: 'PV layout & placement', description: 'Rectangular portrait/landscape fit, manual exclusions and module schedule.', icon: Icons.grid_view_rounded, status: 'Available', tab: 1),
  _Workspace(title: 'Solar yield & savings', description: 'Specific yield, performance ratio, additional losses and tariff-based value.', icon: Icons.wb_sunny_rounded, status: 'Available', tab: 2),
  _Workspace(title: 'Electrical string screening', description: 'Cold-corrected Voc, MPPT voltage window and simple DC cable voltage drop.', icon: Icons.electrical_services_rounded, status: 'Available', tab: 3),
  _Workspace(title: 'Battery & hybrid sizing', description: 'Critical load, autonomy, usable energy, nominal kWh and equivalent Ah.', icon: Icons.battery_charging_full_rounded, status: 'Available', tab: 4),
  _Workspace(title: 'Wind action screening', description: 'Basic velocity pressure and effective-force awareness calculation.', icon: Icons.architecture_rounded, status: 'Available', tab: 5),
  _Workspace(title: 'BOM / BOQ & budget', description: 'Module, inverter, rail, clamp, cable and earthing allowance schedule.', icon: Icons.inventory_2_rounded, status: 'Available', tab: 6),
  _Workspace(title: 'Construction, procurement & QA', description: 'Project-linked vendor/PO record, delivery status, construction QA, test and handover checklists.', icon: Icons.fact_check_rounded, status: 'Available', tab: 7),
  _Workspace(title: 'CAD plan & DXF', description: '2D rectangular roof plan, module preview and metre-unit DXF exchange.', icon: Icons.draw_rounded, status: 'Available', tab: 8),
  _Workspace(title: 'DPR & project documents', description: 'PDF project snapshot, JSON record export and report text.', icon: Icons.description_rounded, status: 'Available', tab: 9),
  _Workspace(title: 'GPS capture & offline mapping', description: 'Device location, map tiles, survey photos and offline map packages.', icon: Icons.map_rounded, status: 'Integration needed', note: 'The current survey screen accepts coordinates manually. Live GPS permission, map display and offline tile management need a platform location/maps integration.'),
  _Workspace(title: 'Advanced roof geometry & 3D', description: 'Polygon roofs, multiple buildings, obstacle volumes and synchronized 3D scene.', icon: Icons.view_in_ar_rounded, status: 'In development', note: 'The current layout and CAD tools support a single rectangular roof zone. Polygon editing, multi-roof optimization and full synchronized 3D are not yet delivered.'),
  _Workspace(title: 'Structural design to IS 875', description: 'Wind zones, load combinations, members, connections and foundations.', icon: Icons.foundation_rounded, status: 'Engineering validation needed', note: 'Only a basic velocity-pressure screening formula is present. Full IS 875 Part 3 design and verified member/foundation checks must be implemented and checked by a qualified structural engineer.'),
  _Workspace(title: 'Advanced procurement lifecycle', description: 'Multiple vendor RFQs, quotation comparisons, staged goods receipts and invoice reconciliation.', icon: Icons.local_shipping_rounded, status: 'In development', note: 'A single vendor / purchase-order record and status tracker are implemented in Delivery. Multi-vendor RFQ issue, quotation normalization, partial goods receipts, invoice matching and audit-controlled approvals remain to be built.'),
  _Workspace(title: 'Weather & shade modelling', description: 'Source-backed solar resource, sun path, obstacle shadows and module losses.', icon: Icons.filter_drama_rounded, status: 'Integration needed', note: 'Yield currently uses an entered specific-yield assumption and an indicative monthly profile. No live weather source or validated time-series shade model is connected.'),
  _Workspace(title: 'Cloud accounts & team roles', description: 'Sign-in, role-based access, sync, audit log and conflict resolution.', icon: Icons.groups_rounded, status: 'Integration needed', note: 'Projects currently remain on the device. This application does not yet include cloud authentication, multi-user permissions or server synchronization.'),
  _Workspace(title: 'Advanced engineering library', description: 'Solar resource, inverter allocation, AC cable, transformer, wind basis, rail, bolts, foundation, earthing, pump and finance calculations.', icon: Icons.engineering_rounded, status: 'Available', note: 'Project-linked advanced engineering calculators.'),
];

class WorkspacesScreen extends ConsumerWidget {
  const WorkspacesScreen({super.key});

  void _open(WidgetRef ref, _Workspace workspace) {
    if (workspace.tab == null) return;
    ref.read(activeWorkspaceTabProvider.notifier).select(workspace.tab!);
    ref.read(appNavigationIndexProvider.notifier).select(3);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeading(title: 'Engineering module directory', subtitle: 'Open a working module or review the integrations and engineering gates still required.'),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 720 ? 3 : constraints.maxWidth > 480 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _workspaces.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 188),
                  itemBuilder: (context, index) => _WorkspaceCard(workspace: _workspaces[index], onTap: () {
                    if (workspace.title == 'Advanced engineering library') {
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdvancedEngineeringScreen()));
                    } else if (workspace.tab != null) {
                      _open(ref, workspace);
                    } else {
                      showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                        icon: Icon(workspace.icon, size: 30),
                        title: Text(workspace.title),
                        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _StatusPill(status: workspace.status),
                          const SizedBox(height: 12),
                          Text(workspace.note),
                        ]),
                        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
                      ));
                    }
                  }),
                );
              }),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFFFF7E9), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFF0E1C4))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.engineering_outlined, color: Color(0xFF9C6A20)), SizedBox(width: 10), Expanded(child: Text('“Available” means a working screen or calculation exists, not that the result is construction approved. “Integration needed” and “In development” identify genuine product gaps. Structural and electrical release requires applicable standards, equipment datasheets and qualified review.', style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF76582B))))])),
            ]),
          ),
        ),
      );
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.workspace, required this.onTap});
  final _Workspace workspace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = workspace.tab != null || workspace.title == 'Advanced engineering library';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: available ? GenSolarTheme.brandMint : const Color(0xFFF1F3F1), borderRadius: BorderRadius.circular(13)), child: Icon(workspace.icon, color: available ? GenSolarTheme.brandGreen : const Color(0xFF758078), size: 22)),
            const Spacer(),
            _StatusPill(status: workspace.status),
          ]),
          const Spacer(),
          Text(workspace.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(workspace.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.35)),
          const SizedBox(height: 9),
          Row(children: [Text(available ? 'Open workspace' : 'View requirements', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: available ? GenSolarTheme.brandGreen : const Color(0xFF727F76))), const Spacer(), Icon(available ? Icons.arrow_forward_rounded : Icons.info_outline_rounded, size: 16, color: available ? GenSolarTheme.brandGreen : const Color(0xFF929C95))]),
        ])),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final available = status == 'Available';
    final tint = available ? const Color(0xFFE6F5EB) : const Color(0xFFF3F1EC);
    final foreground = available ? GenSolarTheme.brandGreen : const Color(0xFF796A4D);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(30)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: foreground)));
  }
}
