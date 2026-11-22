import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/solar_project.dart';
import '../../core/providers.dart';
import '../../shared/widgets/section_heading.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _openingEditor = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openProjectEditor({SolarProject? existing}) async {
    if (_openingEditor) return;
    setState(() => _openingEditor = true);
    try {
      var project = await showDialog<SolarProject>(
        context: context,
        builder: (_) => _ProjectEditorDialog(existing: existing),
      );
      if (!mounted || project == null) return;
      final previous = existing;
      if (previous != null) {
        var engineering = Map<String, Object?>.from(project.engineeringData);
        if (previous.targetCapacityKw != project.targetCapacityKw) {
          engineering = markSectionReview(
            engineering,
            'pv',
            reason: 'Project target DC capacity changed. Recalculate and save the PV layout.',
          );
          engineering = markDownstreamReview(engineering, 'pv');
        }
        if (previous.location.trim() != project.location.trim()) {
          engineering = markSectionReview(
            engineering,
            'survey',
            reason: 'Project site location changed. Verify coordinates and resave the survey.',
          );
          engineering = markDownstreamReview(engineering, 'survey');
        }
        project = project.copyWith(
          engineeringData: engineering,
          status: deriveProjectStatus(engineering),
        );
      }
      await ref.read(projectRepositoryProvider).save(project);
      ref.read(activeProjectIdProvider.notifier).select(project.id);
      ref.invalidate(projectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? 'Project created.' : 'Project details updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project could not be saved: $error')));
      }
    } finally {
      if (mounted) setState(() => _openingEditor = false);
    }
  }

  Future<void> _deleteProject(SolarProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('Remove "${project.name}" and all of its local engineering records from this device? Export a backup first if these records are needed later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete project')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(projectRepositoryProvider).delete(project.id);
      if (ref.read(activeProjectIdProvider) == project.id) {
        ref.read(activeProjectIdProvider.notifier).select(null);
      }
      ref.invalidate(projectsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted from this device.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final activeId = ref.watch(activeProjectIdProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: 'Your projects',
                subtitle: 'One project record connects survey, design, calculations and delivery.',
                action: FilledButton.icon(
                  onPressed: _openingEditor ? null : () => _openProjectEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('New project'),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search project, customer or site',
                  suffixIcon: _query.isEmpty ? null : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              projects.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('Project storage error: $error'))),
                data: (items) {
                  final filtered = items.where((project) {
                    if (_query.isEmpty) return true;
                    return '${project.name} ${project.customer} ${project.location}'.toLowerCase().contains(_query);
                  }).toList();
                  if (items.isEmpty) return _EmptyProjects(onCreate: () => _openProjectEditor());
                  if (filtered.isEmpty) {
                    return Card(child: Padding(padding: const EdgeInsets.all(28), child: Center(child: Column(children: [
                      const Icon(Icons.search_off_rounded, size: 34),
                      const SizedBox(height: 8),
                      const Text('No matching projects'),
                      TextButton(onPressed: () { _searchController.clear(); setState(() => _query = ''); }, child: const Text('Clear search')),
                    ]))));
                  }
                  return Column(children: [
                    Row(children: [
                      Expanded(child: Text('${filtered.length} of ${items.length} project${items.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                      if (activeId != null) const Chip(avatar: Icon(Icons.check_circle, size: 15), label: Text('Active project')),
                    ]),
                    const SizedBox(height: 8),
                    ...filtered.map((project) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ProjectTile(
                        project: project,
                        active: project.id == activeId,
                        onOpen: () {
                          ref.read(activeProjectIdProvider.notifier).select(project.id);
                          ref.read(appNavigationIndexProvider.notifier).select(3);
                          ref.read(activeWorkspaceTabProvider.notifier).select(0);
                        },
                        onEdit: () => _openProjectEditor(existing: project),
                        onDelete: () => _deleteProject(project),
                      ),
                    )),
                  ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
          child: Center(
            child: Column(children: [
              Icon(Icons.solar_power_rounded, size: 46, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('No projects yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Create your first solar EPC project to start planning.'),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create project')),
            ]),
          ),
        ),
      );
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.active, required this.onDelete, required this.onEdit, required this.onOpen});
  final SolarProject project;
  final bool active;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: active ? scheme.primaryContainer.withValues(alpha: .30) : scheme.surface,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: active ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          child: Icon(Icons.solar_power_rounded, color: scheme.primary),
        ),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text([
            if (project.customer.isNotEmpty) project.customer,
            if (project.location.isNotEmpty) project.location,
            '${project.targetCapacityKw.toStringAsFixed(1)} kWp',
            DateFormat.yMMMd().format(project.updatedAt),
          ].join('  •  '), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Project options',
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit details'), dense: true)),
            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete project'), dense: true)),
          ],
        ),
      ),
    );
  }
}

class _ProjectEditorDialog extends StatefulWidget {
  const _ProjectEditorDialog({this.existing});
  final SolarProject? existing;

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _customer;
  late final TextEditingController _location;
  late final TextEditingController _capacity;

  @override
  void initState() {
    super.initState();
    final project = widget.existing;
    _name = TextEditingController(text: project?.name ?? '');
    _customer = TextEditingController(text: project?.customer ?? '');
    _location = TextEditingController(text: project?.location ?? '');
    _capacity = TextEditingController(text: (project?.targetCapacityKw ?? 10).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _customer.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  String? _capacityValidator(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null || !value.isFinite || value <= 0 || value > 100000) {
      return 'Enter a capacity greater than 0 and no more than 100,000 kW.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.existing == null ? 'Create solar project' : 'Edit project details'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Project name *'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter a project name' : null),
                const SizedBox(height: 10),
                TextFormField(controller: _customer, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Customer / company')),
                const SizedBox(height: 10),
                TextFormField(controller: _location, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Site location')),
                const SizedBox(height: 10),
                TextFormField(controller: _capacity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target DC capacity (kW)'), validator: _capacityValidator),
                const SizedBox(height: 8),
                Text('All engineering workspace records remain attached when project details are edited.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final now = DateTime.now().toUtc();
            final existing = widget.existing;
            final project = existing == null
                ? SolarProject(
                    id: 'project-${now.microsecondsSinceEpoch}',
                    name: _name.text.trim(),
                    customer: _customer.text.trim(),
                    location: _location.text.trim(),
                    targetCapacityKw: double.parse(_capacity.text.trim()),
                    createdAt: now,
                    updatedAt: now,
                  )
                : existing.copyWith(
                    name: _name.text.trim(),
                    customer: _customer.text.trim(),
                    location: _location.text.trim(),
                    targetCapacityKw: double.parse(_capacity.text.trim()),
                    updatedAt: now,
                  );
            Navigator.pop(context, project);
          }, child: Text(widget.existing == null ? 'Create project' : 'Save changes')),
        ],
      );
}
