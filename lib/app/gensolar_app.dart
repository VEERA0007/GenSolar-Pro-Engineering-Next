import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import '../core/providers.dart';
import '../core/models/solar_project.dart';
import '../features/calculator/pv_calculator_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/engineering/engineering_workspace_screen.dart';
import '../features/workspaces/workspaces_screen.dart';
import '../core/services/update_release_service.dart';
import '../shared/widgets/update_download_dialog.dart';
import '../core/services/update_installer.dart';

class GenSolarApp extends StatelessWidget {
  const GenSolarApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GenSolar Pro Engineering',
        debugShowCheckedModeBanner: false,
        theme: GenSolarTheme.light(),
        home: const _UpdateGate(child: _ApplicationShell()),
      );
}


class _UpdateGate extends StatefulWidget {
  const _UpdateGate({required this.child});
  final Widget child;

  @override
  State<_UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<_UpdateGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_checked || !mounted) return;
    _checked = true;
    final result = await UpdateReleaseService().checkForUpdate();
    if (!mounted || !result.hasUpdate) return;
    final release = result.release!;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => UpdateDownloadDialog(
        currentVersion: '1.0.0+${release.currentBuildNumber}',
        newVersion: '1.0.0+${release.buildNumber}',
        downloadUrl: release.downloadUrl,
        releaseUrl: release.releaseUrl,
        fileName: release.fileName,
        onDownloaded: (downloadedPath) async {
          final installResult = await UpdateInstaller().install(
            downloadedPath: downloadedPath,
            releaseUrl: release.releaseUrl,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                installResult.message ??
                    (installResult.status == UpdateInstallStatus.launched
                        ? 'Installer opened. Follow the platform installation prompts.'
                        : 'Update package downloaded.'),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Destination {
  const _Destination(this.label, this.subtitle, this.icon, this.selectedIcon);
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData selectedIcon;
}

const _mobileDestinationIndexes = <int>[0, 1, 2, 3, 5];

const _destinations = <_Destination>[
  _Destination('Overview', 'Project command centre', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _Destination('Projects', 'Customers and sites', Icons.folder_copy_outlined, Icons.folder_copy_rounded),
  _Destination('PV sizing', 'Quick engineering tools', Icons.solar_power_outlined, Icons.solar_power_rounded),
  _Destination('EPC workspace', 'Connected design workflow', Icons.hub_outlined, Icons.hub_rounded),
  _Destination('Modules', 'Engineering workspace index', Icons.widgets_outlined, Icons.widgets_rounded),
  _Destination('Settings', 'Backup and preferences', Icons.tune_outlined, Icons.tune_rounded),
];

class _ApplicationShell extends ConsumerStatefulWidget {
  const _ApplicationShell();

  @override
  ConsumerState<_ApplicationShell> createState() => _ApplicationShellState();
}

class _ApplicationShellState extends ConsumerState<_ApplicationShell> {
  static const _pages = <Widget>[
    DashboardScreen(),
    ProjectsScreen(),
    PvCalculatorScreen(),
    EngineeringWorkspaceScreen(),
    WorkspacesScreen(),
    SettingsScreen(),
  ];

  void _select(int index) => ref.read(appNavigationIndexProvider.notifier).select(index);

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(appNavigationIndexProvider);
    final projects = ref.watch(projectsProvider);
    final activeProjectId = ref.watch(activeProjectIdProvider);
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1120;
    final tablet = width >= 760 && width < 1120;
    final projectItems = projects.value ?? const [];
    SolarProject? selectedProject;
    for (final item in projectItems) {
      if (item.id == activeProjectId) { selectedProject = item; break; }
    }
    selectedProject ??= projectItems.isEmpty ? null : projectItems.first;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (desktop) _SideNavigation(selectedIndex: index, onSelect: _select),
            if (tablet)
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                minWidth: 76,
                groupAlignment: -.9,
                destinations: _destinations.map((d) => NavigationRailDestination(
                  icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label),
                )).toList(),
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _destinations[index].label,
                    subtitle: _destinations[index].subtitle,
                    projects: projectItems,
                    selectedProject: selectedProject,
                    onProjectChanged: (id) => ref.read(activeProjectIdProvider.notifier).select(id),
                    onSettings: () => _select(5),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: index,
                      children: _pages,
                    ),
                  ),
                  if (!desktop && !tablet)
                    NavigationBar(
                      // Keep the phone navigation to five high-frequency destinations.
                      // Settings remains available from the top-bar control; the module
                      // directory is reachable from the EPC workspace.
                      selectedIndex: _mobileDestinationIndexes.indexOf(index) < 0
                          ? 3
                          : _mobileDestinationIndexes.indexOf(index),
                      onDestinationSelected: (visibleIndex) =>
                          _select(_mobileDestinationIndexes[visibleIndex]),
                      destinations: _mobileDestinationIndexes.map((destinationIndex) {
                        final destination = _destinations[destinationIndex];
                        return NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: GenSolarTheme.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 16, 24),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A392A), Color(0xFF168A5D)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 11),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GenSolar Pro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.35)),
                Text('ENGINEERING SUITE', style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: Color(0xFF738177), fontWeight: FontWeight.w800)),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Text('WORKSPACE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
          ),
          for (var i = 0; i < _destinations.length; i++)
            _SideNavItem(destination: _destinations[i], selected: selectedIndex == i, onTap: () => onSelect(i)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F7F3), borderRadius: BorderRadius.circular(16)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.cloud_done_outlined, color: GenSolarTheme.brandGreen, size: 19),
              SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Offline workspace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Project data is stored on this device.', style: TextStyle(fontSize: 10, color: Color(0xFF65756B), height: 1.35)),
              ])),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({required this.destination, required this.selected, required this.onTap});
  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(children: [
              Icon(selected ? destination.selectedIcon : destination.icon, size: 20, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(destination.label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant))),
              if (selected) Icon(Icons.chevron_right_rounded, size: 18, color: colors.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.subtitle, required this.projects, required this.selectedProject, required this.onProjectChanged, required this.onSettings});
  final String title;
  final String subtitle;
  final List<SolarProject> projects;
  final SolarProject? selectedProject;
  final ValueChanged<String?> onProjectChanged;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final titleBlock = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF7B887F))),
          ],
        );
        final chooser = projects.isNotEmpty
            ? DropdownButtonFormField<String>(
                initialValue: selectedProject?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.folder_open_outlined, size: 18),
                  labelText: 'Active project',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 4 : 7),
                ),
                items: projects.map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onProjectChanged,
              )
            : const Chip(avatar: Icon(Icons.info_outline, size: 16), label: Text('No active project'));

        return Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 24, vertical: compact ? 8 : 0),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: GenSolarTheme.line))),
          child: compact
              ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [Expanded(child: titleBlock), const SizedBox(width: 8), IconButton(tooltip: 'Settings', onPressed: onSettings, icon: const Icon(Icons.tune_rounded))]),
                  if (projects.isNotEmpty) SizedBox(height: 48, child: chooser)
                  else Align(alignment: Alignment.centerLeft, child: chooser),
                ])
              : SizedBox(
                  height: 76,
                  child: Row(children: [
                    Expanded(child: titleBlock),
                    if (projects.isNotEmpty) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 250), child: chooser) else chooser,
                    const SizedBox(width: 10),
                    IconButton(tooltip: 'Settings', onPressed: onSettings, icon: const Icon(Icons.tune_rounded)),
                  ]),
                ),
        );
      });
}
