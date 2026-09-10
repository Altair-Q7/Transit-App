import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.bus, this.location, this.stop});
  final DemoBus? bus;
  final DemoLocation? location;
  final String? stop;
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late DemoBus bus;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    bus = widget.bus ?? MockData.buses['Aluva']!.first;
    timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => bus.progress = (bus.progress + .009) % 1);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location ?? MockData.locations.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Live tracking')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _map(location),
          const SizedBox(height: 18),
          const Text(
            '●  Live GPS tracking',
            style: TextStyle(
              color: Color(0xff21a179),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(19),
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
                  Text(
                    bus.route,
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _metric(bus.eta, 'Arrival'),
                      _metric('${bus.speed.toInt()} km/h', 'Speed'),
                      _metric(
                        '${(bus.confidence * 100).toInt()}%',
                        'Confidence',
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Text(
                    'Next stop: ${bus.nextStop}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${bus.stopsRemaining} stops remaining  •  Destination: ${bus.destination}',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journey progress',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: bus.progress,
                    minHeight: 8,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: const Color(0xffff7b45),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Live position is updating smoothly',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
        ),
      ],
    ),
  );
  Widget _map(DemoLocation l) => Container(
    height: 245,
    decoration: BoxDecoration(
      color: const Color(0xffe6eff1),
      borderRadius: BorderRadius.circular(25),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter(bus.progress, l.color)),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${l.name} demo map',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            right: 14,
            child: FloatingActionButton.small(
              heroTag: 'loc',
              onPressed: () {},
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0xff3977e8),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.progress, this.color);
  final double progress;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final roads = Paint()
      ..color = Colors.white.withOpacity(.8)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    c.drawLine(
      Offset(0, s.height * .76),
      Offset(s.width, s.height * .25),
      roads,
    );
    c.drawLine(
      Offset(s.width * .18, 0),
      Offset(s.width * .78, s.height),
      roads,
    );
    final route = Paint()
      ..color = const Color(0xffff7b45)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(s.width * .08, s.height * .75)
      ..quadraticBezierTo(
        s.width * .36,
        s.height * .2,
        s.width * .86,
        s.height * .3,
      );
    c.drawPath(path, route);
    final p = Offset(
      s.width * (.08 + progress * .78),
      s.height * (.75 - progress * .45),
    );
    c.drawCircle(p, 14, Paint()..color = color.withOpacity(.18));
    c.drawCircle(p, 7, Paint()..color = color);
    c.drawCircle(
      Offset(s.width * .18, s.height * .76),
      6,
      Paint()..color = const Color(0xff3977e8),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.progress != progress;
}
