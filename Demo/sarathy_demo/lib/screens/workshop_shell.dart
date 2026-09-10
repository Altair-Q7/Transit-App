import 'package:flutter/material.dart';
import 'settings_screen.dart';

enum JobStage { requested, confirmed, inspection, repair, ready, completed }

class WorkshopShell extends StatefulWidget {
  const WorkshopShell({super.key, this.onThemeChanged});
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override
  State<WorkshopShell> createState() => _WorkshopShellState();
}

class _WorkshopShellState extends State<WorkshopShell> {
  int tab = 0;
  JobStage stage = JobStage.requested;
  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _bookings(), _fleet(), _more()];
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
            icon: Icon(Icons.assignment_outlined),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _dashboard() => _page('Workshop Command', [
    const Text(
      'Sarathy Care Aluva  •  WS-ALV-01',
      style: TextStyle(color: Colors.blueGrey),
    ),
    const SizedBox(height: 20),
    Row(
      children: [
        _stat('4', 'Pending'),
        _stat('7', 'Confirmed'),
        _stat('3', 'In service'),
        _stat('2', 'Ready'),
      ],
    ),
    const SizedBox(height: 22),
    const Text(
      'Urgent request',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
    Card(
      color: const Color(0xfffff2ed),
      child: ListTile(
        onTap: _details,
        leading: const Icon(Icons.priority_high_rounded, color: Colors.red),
        title: const Text(
          'Sarathy 101 • Emergency',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Brake warning • Arun Raj • Aluva'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    ),
    const SizedBox(height: 20),
    const Text(
      'Quick actions',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        _quick(Icons.add_circle_outline, 'New booking', _newBooking),
        _quick(
          Icons.assignment_outlined,
          'Requests',
          () => setState(() => tab = 1),
        ),
        _quick(Icons.analytics_outlined, 'Analytics', _analytics),
      ],
    ),
  ]);
  Widget _stat(String value, String label) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xff3977e8),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        onPressed: onTap,
        child: Column(
          children: [
            Icon(icon, color: const Color(0xff3977e8)),
            Text(label, style: const TextStyle(fontSize: 9)),
          ],
        ),
      ),
    ),
  );
  Widget _bookings() => _page('Booking management', [
    const Text(
      'Incoming service requests',
      style: TextStyle(color: Colors.blueGrey),
    ),
    const SizedBox(height: 14),
    _job('WB-2048', 'Sarathy 101', 'Brake service • Emergency', Colors.red),
    _job(
      'WB-2045',
      'Sarathy 203',
      'General inspection • Normal',
      Colors.orange,
    ),
    _job(
      'WB-2041',
      'Sarathy 302',
      'Electrical • Confirmed',
      const Color(0xff3977e8),
    ),
  ]);
  Widget _job(String id, String bus, String service, Color color) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: _details,
      leading: Icon(Icons.assignment_rounded, color: color),
      title: Text(
        '$id  •  $bus',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('$service\nToday at 2:30 PM'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
  Widget _fleet() => _page('Workshop fleet', [
    const Text(
      'Vehicle condition across Sarathy services',
      style: TextStyle(color: Colors.blueGrey),
    ),
    const SizedBox(height: 14),
    ...[
      'Sarathy 101 • KL-07-AB-1234',
      'Sarathy 203 • KL-07-CD-5521',
      'Sarathy 302 • KL-01-EF-8842',
    ].map(
      (b) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          onTap: _vehicle,
          leading: const Icon(
            Icons.directions_bus_rounded,
            color: Color(0xff3977e8),
          ),
          title: Text(b, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('128,420 km • Last service 14 Aug 2026'),
          trailing: const Text(
            'READY',
            style: TextStyle(
              color: Color(0xff21a179),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  ]);
  Widget _more() => _page('Workshop tools', [
    ListTile(
      onTap: _analytics,
      leading: const Icon(Icons.analytics_outlined, color: Color(0xff3977e8)),
      title: const Text('Analytics'),
      subtitle: const Text('42 completed jobs • 94% completion rate'),
    ),
    ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SettingsScreen(onThemeChanged: widget.onThemeChanged ?? (_) {}),
        ),
      ),
      leading: const Icon(Icons.settings_outlined, color: Color(0xff3977e8)),
      title: const Text('Settings'),
    ),
    const Card(
      child: ListTile(
        leading: Icon(Icons.build_rounded, color: Color(0xffff7b45)),
        title: Text(
          'Sarathy Care Aluva',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('4 service bays • 12 technicians • ★ 4.8'),
      ),
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
  void _details() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('WB-2048 • Sarathy 101'),
      content: Text(
        'Emergency brake inspection\nCrew: Arun Raj\nLocation: Aluva\nStatus: ${stage.name.toUpperCase()}\n\nInspection: Brakes require attention.\nTechnician: Meera Nair\nService bay: Bay 02',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            if (stage != JobStage.completed)
              setState(() => stage = JobStage.values[stage.index + 1]);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status updated. Crew has been notified.'),
              ),
            );
          },
          child: const Text('Advance status'),
        ),
      ],
    ),
  );
  void _vehicle() => showDialog(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('Vehicle details'),
      content: Text(
        'Sarathy 101 • KL-07-AB-1234\nOperational\nLast service: 14 Aug 2026\nNext service: 14 Nov 2026\nService history: 8 completed jobs',
      ),
      actions: [TextButton(onPressed: null, child: Text('Close'))],
    ),
  );
  void _newBooking() => _snack('Booking created and crew notified.');
  void _analytics() => showDialog(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('Workshop analytics'),
      content: Text(
        'Jobs completed       42\nJobs pending          11\nAverage service      2h 35m\nVehicles serviced    38\nCompletion rate       94%',
      ),
      actions: [TextButton(onPressed: null, child: Text('Close'))],
    ),
  );
  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
