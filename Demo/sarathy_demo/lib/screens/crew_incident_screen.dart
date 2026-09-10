import 'package:flutter/material.dart';

class IncidentScreen extends StatelessWidget {
  const IncidentScreen({super.key, this.type, required this.onSubmitted});
  final String? type;
  final VoidCallback onSubmitted;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report incident')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              type ?? 'Other incident',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Current simulated location: Near Kalamassery',
              style: TextStyle(color: Colors.blueGrey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  onSubmitted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Incident reported successfully. Operations has been notified.',
                      ),
                    ),
                  );
                },
                child: const Text('Submit incident'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
