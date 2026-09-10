import 'package:flutter/material.dart';
import '../models/models.dart';
import 'crew_incident_screen.dart';

class CrewActiveTripScreen extends StatelessWidget {
  const CrewActiveTripScreen({
    super.key,
    required this.bus,
    required this.duration,
    required this.pings,
    required this.connection,
    required this.onIncident,
    required this.onComplete,
  });
  final DemoBus bus;
  final int duration, pings;
  final ConnectionStateDemo connection;
  final VoidCallback onIncident, onComplete;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Active trip')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xffdfecef),
            borderRadius: BorderRadius.circular(24),
          ),
          child: CustomPaint(painter: _Map(bus.progress)),
        ),
        const SizedBox(height: 18),
        const Text(
          '●  GPS transmitting',
          style: TextStyle(
            color: Color(0xff21a179),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.id,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(bus.route, style: const TextStyle(color: Colors.blueGrey)),
                const Divider(height: 28),
                Text(
                  'Duration  ${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}    Ping #$pings',
                ),
                const SizedBox(height: 12),
                Text(
                  'Speed ${bus.speed.toInt()} km/h   •   Next stop ${bus.nextStop}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _button(context, 'Traffic', Colors.orange),
            _button(context, 'Breakdown', Colors.red),
            _button(context, 'Emergency', Colors.red),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onIncident,
          child: const Text('Other incident'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onComplete,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff11243e),
          ),
          child: const Text('Complete trip'),
        ),
      ],
    ),
  );
  Widget _button(BuildContext context, String label, Color color) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncidentScreen(
              type: label,
              onSubmitted: () => Navigator.pop(context),
            ),
          ),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      ),
    ),
  );
}

class _Map extends CustomPainter {
  const _Map(this.progress);
  final double progress;
  @override
  void paint(Canvas c, Size s) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 20;
    c.drawLine(Offset(0, s.height * .8), Offset(s.width, s.height * .2), road);
    final route = Paint()
      ..color = const Color(0xffff7b45)
      ..strokeWidth = 6;
    c.drawLine(
      Offset(20, s.height * .75),
      Offset(s.width - 20, s.height * .3),
      route,
    );
    c.drawCircle(
      Offset(20 + progress * (s.width - 40), s.height * (.75 - progress * .45)),
      9,
      Paint()..color = const Color(0xffff7b45),
    );
  }

  @override
  bool shouldRepaint(covariant _Map old) => old.progress != progress;
}
