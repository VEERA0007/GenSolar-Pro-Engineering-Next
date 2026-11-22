import 'package:material_ui/material_ui.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helper;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 15),
              Text(value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: 3),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              if (helper != null) ...[
                const SizedBox(height: 4),
                Text(helper!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ],
            ],
          ),
        ),
      );
}
