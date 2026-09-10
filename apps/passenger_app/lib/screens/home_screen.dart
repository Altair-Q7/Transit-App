import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/api_service.dart';
import '../widgets/eta_card.dart';
import 'live_tracking_screen.dart';

/// Passenger Access (flywheel node 5): "Search ETA".
/// For the MVP scaffold, stop selection is a hardcoded demo list —
/// wire this up to a real stop search/autocomplete endpoint later.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _DemoStop {
  final int id;
  final String name;
  const _DemoStop(this.id, this.name);
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  final _demoStops = const [
    _DemoStop(1, 'Aluva Railway Station'),
    _DemoStop(2, 'Vytilla Hub'),
    _DemoStop(3, 'Kakkanad Infopark Gate'),
  ];

  List<EtaEstimate> _results = [];
  int? _selectedStopId;
  String _selectedStopName = '';
  bool _loading = false;
  String? _error;

  Future<void> _search(_DemoStop stop) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedStopId = stop.id;
      _selectedStopName = stop.name;
    });
    try {
      final results = await _api.getEtaForStop(stop.id);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sarathy — Your Journey, Guided.')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: _demoStops
                  .map((s) => ChoiceChip(
                        label: Text(s.name),
                        selected: _selectedStopId == s.id,
                        onSelected: (_) => _search(s),
                      ))
                  .toList(),
            ),
          ),
          if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Couldn\'t load ETA: $_error', style: const TextStyle(color: Colors.red)),
            ),
          if (!_loading && _error == null && _selectedStopId != null && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No buses currently active on this route.'),
            ),
          ..._results.map(
            (r) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LiveTrackingScreen(tripId: r.tripId, stopName: _selectedStopName),
                ),
              ),
              child: EtaCard(stopName: _selectedStopName, estimate: r),
            ),
          ),
        ],
      ),
    );
  }
}
