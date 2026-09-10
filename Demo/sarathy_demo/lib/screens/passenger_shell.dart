import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import 'tracking_screen.dart';
import 'settings_screen.dart';

class PassengerShell extends StatefulWidget {
  const PassengerShell({super.key, required this.onThemeChanged});
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int tab = 0;
  DemoLocation location = MockData.locations.first;
  ConnectionStateDemo connection = ConnectionStateDemo.online;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted)
        setState(() {
          for (final b in MockData.buses[location.name]!)
            b.progress = (b.progress + .012) % 1;
        });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _search(), _trips(), _alerts(), _account()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _home() {
    final buses = MockData.buses[location.name]!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Good morning, Anjali',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => tab = 3),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        GestureDetector(
          onTap: _chooseLocation,
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 17,
                color: Color(0xffff7b45),
              ),
              Text(
                '  ${location.name}  •  Demo location',
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _connection(),
        const SizedBox(height: 18),
        TextField(
          readOnly: true,
          onTap: () => setState(() => tab = 1),
          decoration: const InputDecoration(
            hintText: 'Where are you going?',
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: Icon(Icons.tune_rounded),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nearby buses',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => tab = 1),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...buses.take(3).map(_busCard),
        const SizedBox(height: 14),
        _alertCard(),
      ],
    );
  }

  void _chooseLocation() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose demo location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            ...MockData.locations.map(
              (l) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: l.color.withOpacity(.12),
                  child: Text(
                    l.code,
                    style: TextStyle(
                      color: l.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(l.name),
                subtitle: Text(l.subtitle),
                trailing: location.name == l.name
                    ? const Icon(Icons.check_circle, color: Color(0xff3977e8))
                    : null,
                onTap: () {
                  setState(() => location = l);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connection() {
    final colors = [
      const Color(0xff21a179),
      Colors.orange,
      Colors.red,
      Colors.orange,
    ];
    final texts = [
      'Live information is up to date',
      'Weak connection · updates may be delayed',
      'You’re offline · showing last known data',
      'Reconnecting to live services…',
    ];
    final i = connection.index;
    return GestureDetector(
      onTap: () =>
          setState(() => connection = ConnectionStateDemo.values[(i + 1) % 4]),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors[i].withOpacity(.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              i == 2 ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: colors[i],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texts[i],
                style: TextStyle(
                  color: colors[i],
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Text(
              'Tap to simulate',
              style: TextStyle(color: Colors.blueGrey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _busCard(DemoBus bus) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(bus: bus, location: location),
        ),
      ),
      contentPadding: const EdgeInsets.all(15),
      leading: CircleAvatar(
        backgroundColor: bus.color.withOpacity(.12),
        child: Icon(Icons.directions_bus_rounded, color: bus.color),
      ),
      title: Text(bus.id, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(bus.route),
      trailing: Text(
        bus.eta,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ),
  );
  Widget _alertCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xfffff4ee),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xffff7b45)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Marine Drive traffic may add 6–8 minutes to Fort Kochi routes.',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    ),
  );
  Widget _search() => _page('Find your bus', [
    TextField(
      decoration: const InputDecoration(
        hintText: 'Search stops, routes or bus numbers',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    ),
    const SizedBox(height: 24),
    const Text(
      'Nearby stops',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 12),
    Card(
      child: ListTile(
        title: Text(MockData.stops.first.name),
        subtitle: Text(
          '${MockData.stops.first.distance} • ${MockData.stops.first.buses}',
        ),
        trailing: Text(MockData.stops.first.eta),
      ),
    ),
    Card(
      child: ListTile(
        title: Text(MockData.stops[1].name),
        subtitle: Text(
          '${MockData.stops[1].distance} • ${MockData.stops[1].buses}',
        ),
        trailing: Text(MockData.stops[1].eta),
      ),
    ),
  ]);
  Widget _trips() => _page('Your journeys', [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff11243e),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xffff7b45),
            child: Icon(Icons.route_rounded, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your active trip',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 4),
                Text(
                  'Vytilla  →  Fort Kochi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white70,
            size: 16,
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    const Text(
      'Saved journeys',
      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 12),
    _trip('Home to work', 'Aluva → Kakkanad'),
    _trip('Weekend in Fort Kochi', 'Vytilla → Fort Kochi'),
  ]);
  Widget _trip(String title, String route) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const Icon(
        Icons.favorite_border_rounded,
        color: Color(0xffff7b45),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(route),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
  Widget _alerts() => _page(
    'Notifications',
    MockData.notifications
        .map(
          (n) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: n.color.withOpacity(.12),
                child: Icon(n.icon, color: n.color),
              ),
              title: Text(
                n.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${n.body}\n${n.time}'),
              isThreeLine: true,
            ),
          ),
        )
        .toList(),
  );
  Widget _account() => _page('Account', [
    Card(
      child: const ListTile(
        contentPadding: EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 31,
          backgroundColor: Color(0xffffe4d9),
          child: Text(
            'AS',
            style: TextStyle(
              color: Color(0xffff7b45),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          'Anjali Suresh',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        subtitle: Text('anjali@sarathy.app\n+91 98765 43210'),
      ),
    ),
    const SizedBox(height: 18),
    _accountTile(
      Icons.favorite_border_rounded,
      'Favourite stops',
      'Aluva Metro Station, Vytilla Hub',
    ),
    _accountTile(
      Icons.bookmark_border_rounded,
      'Saved routes',
      '2 routes saved',
    ),
    _accountTile(
      Icons.settings_outlined,
      'Settings',
      'Theme, notifications and preferences',
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged),
        ),
      ),
    ),
    TextButton.icon(
      onPressed: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreenPlaceholder()),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Log out'),
    ),
  ]);
  Widget _accountTile(
    IconData i,
    String title,
    String sub, [
    VoidCallback? onTap,
  ]) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      onTap: onTap,
      leading: Icon(i, color: const Color(0xff3977e8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
  Widget _page(String title, List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 23, 22, 30),
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 22),
      ...children,
    ],
  );
}

class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Signed out')));
}
