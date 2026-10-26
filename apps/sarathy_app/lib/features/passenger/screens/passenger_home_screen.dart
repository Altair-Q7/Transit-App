import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models.dart';
import '../../../services.dart';
import '../widgets/eta_card.dart';

/// Passenger Access (flywheel node 5): "Search ETA".
/// Stop selection uses the public stop-search endpoint before loading ETAs.
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<Stop> _stops = [];

  List<EtaEstimate> _results = [];
  int? _selectedStopId;
  String _selectedStopName = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchStops() async {
    final query = _searchController.text.trim();
    if (query.length < 2) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final stops = await _api.searchStops(query);
      if (mounted) setState(() => _stops = stops);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search(Stop stop) async {
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
      if (mounted) setState(() => _loading = false);
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchStops(),
              decoration: InputDecoration(
                labelText: 'Search bus stop',
                hintText: 'e.g. Aluva or Infopark',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchStops,
                ),
              ),
            ),
          ),
          if (_stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: _stops
                    .map((stop) => ChoiceChip(
                          label: Text(stop.name),
                          selected: _selectedStopId == stop.id,
                          onSelected: (_) => _search(stop),
                        ))
                    .toList(),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Couldn\'t load ETA: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (!_loading && _error == null && _selectedStopId != null && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No buses currently active on this route.'),
            ),
          ..._results.map(
            (r) => GestureDetector(
              onTap: () => context.goNamed(
                'passengerTracking',
                pathParameters: {'tripId': r.tripId.toString()},
                queryParameters: {'stopName': _selectedStopName},
              ),
              child: EtaCard(stopName: _selectedStopName, estimate: r),
            ),
          ),
        ],
      ),
    );
  }
}
