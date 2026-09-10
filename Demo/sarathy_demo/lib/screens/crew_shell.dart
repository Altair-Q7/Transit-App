import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import 'crew_active_trip_screen.dart';
import 'crew_incident_screen.dart';
import 'workshop_screen.dart';
import 'settings_screen.dart';

class CrewShell extends StatefulWidget {
  const CrewShell({super.key, this.onThemeChanged});
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override
  State<CrewShell> createState() => _CrewShellState();
}

class _CrewShellState extends State<CrewShell> {
  final DemoBus bus = MockData.buses['Aluva']!.first;
  int tab = 0;
  bool active = false;
  int seconds = 0, pings = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Crew Command'),
          content: const Text(
            'Start your assigned trip, keep GPS active, and report incidents to Operations.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }

  void startTrip() {
    setState(() => active = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted)
        setState(() {
          seconds++;
          pings++;
          bus.progress = (bus.progress + .006) % 1;
        });
    });
  }

  void completeTrip() {
    timer?.cancel();
    setState(() => active = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip completed. Summary saved.')),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _inbox(), _workshop(), _account()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            label: 'Workshop',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _dashboard() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Crew Command',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      const Text(
        'Good morning, Arun  •  Crew ID CRW-042',
        style: TextStyle(color: Colors.blueGrey),
      ),
      const SizedBox(height: 22),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xffffeee8),
            child: Icon(
              Icons.directions_bus_rounded,
              color: Color(0xffff7b45),
              size: 28,
            ),
          ),
          title: const Text(
            'Sarathy 101',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
          subtitle: const Text('Assigned route\nAluva – Fort Kochi'),
          trailing: _pill(
            active ? 'ACTIVE' : 'READY',
            active ? const Color(0xff21a179) : const Color(0xff3977e8),
          ),
        ),
      ),
      const SizedBox(height: 13),
      Card(
        color: const Color(0xff11243e),
        child: ListTile(
          leading: Icon(
            active ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
            color: active ? const Color(0xff5be0b0) : Colors.white70,
          ),
          title: Text(
            active ? 'GPS transmitting' : 'GPS ready to connect',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            active
                ? 'Ping #$pings  •  12 m accuracy'
                : 'Location sharing starts with your trip',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          trailing: Text(
            active ? 'LIVE' : 'READY',
            style: const TextStyle(
              color: Color(0xff5be0b0),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 64,
        child: FilledButton.icon(
          onPressed: active
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CrewActiveTripScreen(
                      bus: bus,
                      duration: seconds,
                      pings: pings,
                      connection: ConnectionStateDemo.online,
                      onIncident: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentScreen(
                            onSubmitted: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      onComplete: completeTrip,
                    ),
                  ),
                )
              : startTrip,
          icon: Icon(
            active ? Icons.open_in_new_rounded : Icons.play_arrow_rounded,
            size: 27,
          ),
          label: Text(
            active ? 'OPEN ACTIVE TRIP' : 'START TRIP',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: active
                ? const Color(0xff21a179)
                : const Color(0xffff7b45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
      ),
      const SizedBox(height: 23),
      const Text(
        "Today's trips",
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      _trip('06:30', 'Aluva → Fort Kochi', active ? 'In progress' : 'Ready'),
      _trip('11:45', 'Fort Kochi → Aluva', 'Assigned'),
      _trip('17:15', 'Aluva → Kakkanad', 'Assigned'),
    ],
  );
  Widget _trip(String time, String route, String status) => Card(
    margin: const EdgeInsets.only(top: 9),
    child: ListTile(
      leading: Text(time, style: const TextStyle(fontWeight: FontWeight.w800)),
      title: Text(route, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Text(
        status,
        style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
      ),
    ),
  );
  Widget _inbox() => _page('Operations inbox', [
    const _Notice(
      'Route update',
      'Keep to the service road near Kalamassery today.',
      Icons.alt_route_rounded,
    ),
    const _Notice(
      'Maintenance reminder',
      'Sarathy 101 is due for a brake inspection after this shift.',
      Icons.build_circle_outlined,
    ),
    const _Notice(
      'Trip assignment',
      'Your 17:15 Aluva → Kakkanad service is confirmed.',
      Icons.assignment_turned_in_outlined,
    ),
  ]);
  Widget _workshop() => _page('Workshop access', [
    const Text(
      'Find service near your current demo location.',
      style: TextStyle(color: Colors.blueGrey),
    ),
    const SizedBox(height: 16),
    WorkshopCard(
      name: 'Sarathy Care Aluva',
      location: 'Aluva • 1.8 km',
      services: 'Brake · Electrical · Inspection',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkshopScreen()),
      ),
    ),
    WorkshopCard(
      name: 'Kochi Fleet Works',
      location: 'Kochi • 8.4 km',
      services: 'Engine · Tyres · AC service',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkshopScreen()),
      ),
    ),
    WorkshopCard(
      name: 'Capital Motor Care',
      location: 'Thiruvananthapuram • 3.2 km',
      services: 'Preventive · Brake · Tyre service',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkshopScreen()),
      ),
    ),
  ]);
  Widget _account() => _page('Crew account', [
    const Card(
      child: ListTile(
        contentPadding: EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 29,
          backgroundColor: Color(0xffffe4e0),
          child: Text('AR'),
        ),
        title: Text(
          'Arun Raj',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        subtitle: Text('Crew ID CRW-042\nAssigned operator: Sarathy Transit'),
      ),
    ),
    const SizedBox(height: 12),
    const ListTile(
      title: Text('Assigned bus'),
      subtitle: Text('Sarathy 101'),
      leading: Icon(Icons.directions_bus_outlined, color: Color(0xff3977e8)),
    ),
    const ListTile(
      title: Text('Work statistics'),
      subtitle: Text('18 trips this month • 96% on-time'),
      leading: Icon(Icons.bar_chart_rounded, color: Color(0xff3977e8)),
    ),
    ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SettingsScreen(onThemeChanged: widget.onThemeChanged ?? (_) {}),
        ),
      ),
      title: const Text('Settings'),
      leading: const Icon(Icons.settings_outlined, color: Color(0xff3977e8)),
    ),
  ]);
  Widget _page(String title, List<Widget> children) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 20),
      ...children,
    ],
  );
  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.title, this.body, this.icon);
  final String title, body;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.all(15),
      leading: Icon(icon, color: const Color(0xff3977e8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(body),
    ),
  );
}
