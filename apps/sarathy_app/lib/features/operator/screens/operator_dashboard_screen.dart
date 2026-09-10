import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../services.dart';

/// Operator dashboard with KPI tiles.
/// Mirrors the web-admin dashboard page.
class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  final _api = ApiService();
  OperatorStats? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final token = await AuthService.getOperatorToken();
      if (token != null) {
        final stats = await _api.getOperatorStats(token);
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _stats == null
                  ? const Center(child: Text('No data'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Live snapshot of your fleet — the same numbers behind the MVP success metrics.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _KpiTile(
                                label: 'Buses in fleet',
                                value: _stats!.fleetSize.toString(),
                              ),
                              _KpiTile(
                                label: 'Active trips now',
                                value: _stats!.activeTrips.toString(),
                              ),
                              _KpiTile(
                                label: 'Stop searches (platform)',
                                value: _stats!.stopSearchesTotal.toString(),
                              ),
                              _KpiTile(
                                label: 'Availability target',
                                value: _stats!.availabilityTarget,
                                hint: 'p95 < ${_stats!.p95TargetMs}ms',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}