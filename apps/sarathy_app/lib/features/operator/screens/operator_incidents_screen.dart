import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../services.dart';

/// Incidents management screen for operators.
/// View and verify incidents reported by crew.
class OperatorIncidentsScreen extends StatefulWidget {
  const OperatorIncidentsScreen({super.key});

  @override
  State<OperatorIncidentsScreen> createState() => _OperatorIncidentsScreenState();
}

class _OperatorIncidentsScreenState extends State<OperatorIncidentsScreen> {
  // TODO: Add API endpoint to list incidents for operator
  // For now, this is a placeholder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidents')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incidents', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Incidents reported by crew awaiting verification.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.report_problem, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Incident list goes here',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Requires backend endpoint to list incidents for operator.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}