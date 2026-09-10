import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../services.dart';

/// Fleet management screen - list and add buses.
class OperatorFleetScreen extends StatefulWidget {
  const OperatorFleetScreen({super.key});

  @override
  State<OperatorFleetScreen> createState() => _OperatorFleetScreenState();
}

class _OperatorFleetScreenState extends State<OperatorFleetScreen> {
  final _api = ApiService();
  List<Bus> _buses = [];
  String? _error;
  bool _loading = true;

  final _regCtrl = TextEditingController();
  int _capacity = 45;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBuses() async {
    try {
      final token = await AuthService.getOperatorToken();
      if (token != null) {
        final buses = await _api.listBuses(token);
        setState(() {
          _buses = buses;
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

  Future<void> _addBus() async {
    if (_regCtrl.text.trim().isEmpty) return;
    try {
      final token = await AuthService.getOperatorToken();
      if (token != null) {
        await _api.addBus(token, _regCtrl.text.trim(), _capacity);
        _regCtrl.clear();
        _loadBuses();
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fleet', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('Every bus registered under your operator account.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _regCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Registration number',
                                  hintText: 'KL-07-AB-1234',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Capacity'),
                                onChanged: (v) => _capacity = int.tryParse(v) ?? 45,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _addBus,
                                child: const Text('Add bus'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buses.isEmpty
                            ? const Center(child: Text('No buses yet — add your first one above.'))
                            : ListView.builder(
                                itemCount: _buses.length,
                                itemBuilder: (context, index) {
                                  final bus = _buses[index];
                                  return ListTile(
                                    leading: const Icon(Icons.directions_bus),
                                    title: Text(bus.registrationNumber),
                                    subtitle: Text('${bus.capacity} seats'),
                                    trailing: Chip(
                                      label: Text(bus.active ? 'Active' : 'Inactive'),
                                      backgroundColor: bus.active ? Colors.green[100] : Colors.grey[300],
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