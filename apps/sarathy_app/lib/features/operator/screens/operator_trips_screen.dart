import 'package:flutter/material.dart';

/// Live trips monitoring screen.
/// Placeholder for map view - subscribe to /ws/trip/{id} per active trip and plot the live lat/lng.
class OperatorTripsScreen extends StatelessWidget {
  const OperatorTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Trips')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Trips', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Trips currently broadcasting GPS pings over the WebSocket channel.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Map view goes here',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Subscribe to /ws/trip/{id} per active trip and plot the live lat/lng.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}