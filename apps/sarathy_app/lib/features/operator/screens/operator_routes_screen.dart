import 'package:flutter/material.dart' hide Route;
import '../../../../models.dart' as models;
import '../../../../services.dart';

/// Routes & stops management screen.
class OperatorRoutesScreen extends StatefulWidget {
  const OperatorRoutesScreen({super.key});

  @override
  State<OperatorRoutesScreen> createState() => _OperatorRoutesScreenState();
}

class _OperatorRoutesScreenState extends State<OperatorRoutesScreen> {
  final _api = ApiService();
  List<models.Route> _routes = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final token = await AuthService.getOperatorToken();
      if (token != null) {
        final routes = await _api.listRoutes(token);
        setState(() {
          _routes = routes;
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
      appBar: AppBar(title: const Text('Routes & Stops')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Routes & Stops', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text("Each route's stops are what passengers search against for a live ETA.",
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _routes.isEmpty
                            ? const Center(
                                child: Text('No routes yet. Create one via the API (POST /routes).'))
                            : ListView.builder(
                                itemCount: _routes.length,
                                itemBuilder: (context, index) {
                                  final route = _routes[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(route.name,
                                              style: Theme.of(context).textTheme.titleLarge),
                                          const SizedBox(height: 4),
                                          Text('${route.origin} → ${route.destination}',
                                              style: Theme.of(context).textTheme.bodyMedium),
                                          const SizedBox(height: 12),
                                          ...route.stops.map((stop) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${stop.sequence}. ${stop.name}',
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: Colors.grey,
                                                            fontFamily: 'monospace',
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}