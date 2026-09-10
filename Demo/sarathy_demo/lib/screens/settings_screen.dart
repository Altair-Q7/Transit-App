import 'package:flutter/material.dart';
import '../widgets/brand_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeChanged});
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  ThemeMode selected = ThemeMode.light;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
      children: [
        const SarathyBrand(module: 'settings'),
        const SizedBox(height: 24),
        _section('Appearance'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text(
                  'Theme',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(selected == ThemeMode.dark ? 'Dark' : 'Light'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {selected},
                  onSelectionChanged: (v) {
                    setState(() => selected = v.first);
                    widget.onThemeChanged(v.first);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _section('Preferences'),
        Card(
          child: Column(
            children: [
              _switch(
                Icons.notifications_none_rounded,
                'Notifications',
                'Service updates and trip alerts',
                notifications,
                (v) => setState(() => notifications = v),
              ),
              _row(Icons.language_rounded, 'Language', 'English'),
              _row(
                Icons.location_on_outlined,
                'Location preferences',
                'Use selected demo location',
              ),
              _row(Icons.data_usage_rounded, 'Data usage', 'Standard quality'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _section('Support & privacy'),
        Card(
          child: Column(
            children: [
              _row(
                Icons.shield_outlined,
                'Privacy',
                'Your demo data stays on this device',
              ),
              _row(
                Icons.help_outline_rounded,
                'Help & support',
                'FAQs and contact support',
              ),
              _row(
                Icons.info_outline_rounded,
                'About Sarathy',
                'Version 1.0.0 · Demo build',
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        color: Colors.blueGrey,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
  Widget _row(IconData i, String t, String s) => ListTile(
    leading: Icon(i, color: const Color(0xff3977e8)),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(s),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
  Widget _switch(
    IconData i,
    String t,
    String s,
    bool v,
    ValueChanged<bool> on,
  ) => SwitchListTile(
    value: v,
    onChanged: on,
    secondary: Icon(i, color: const Color(0xff3977e8)),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(s),
  );
}
