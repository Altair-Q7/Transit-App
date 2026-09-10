import 'package:flutter/material.dart';

class WorkshopCard extends StatelessWidget {
  const WorkshopCard({
    super.key,
    required this.name,
    required this.location,
    required this.services,
    required this.onTap,
  });
  final String name, location, services;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.build_rounded, color: Color(0xff3977e8)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('$location\n$services\n★ 4.8 • Available today'),
    ),
  );
}

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({super.key});
  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  bool booked = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workshop booking')),
      body: booked ? _done() : _form(),
    );
  }

  Widget _form() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request a service',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sarathy Care Aluva • Available today',
          style: TextStyle(color: Colors.blueGrey),
        ),
        const SizedBox(height: 20),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Service type',
            hintText: 'General inspection',
          ),
        ),
        const SizedBox(height: 15),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Problem description'),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => booked = true),
            child: const Text('Request booking'),
          ),
        ),
      ],
    ),
  );
  Widget _done() => const Column(
    children: [
      SizedBox(height: 50),
      Icon(Icons.check_circle_rounded, color: Color(0xff21a179), size: 70),
      SizedBox(height: 18),
      Text(
        'Booking requested',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
      ),
      SizedBox(height: 10),
      Text(
        'Sarathy Care Aluva will confirm shortly.',
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 20),
      Card(
        child: ListTile(
          title: Text('Sarathy 101 • General Inspection'),
          subtitle: Text('Today at 2:30 PM • Status: Requested'),
        ),
      ),
    ],
  );
}
