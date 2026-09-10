import 'package:flutter/material.dart';
import 'workshop_shell.dart';

class WorkshopLoginScreen extends StatefulWidget {
  const WorkshopLoginScreen({super.key, this.onThemeChanged});
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override
  State<WorkshopLoginScreen> createState() => _WorkshopLoginScreenState();
}

class _WorkshopLoginScreenState extends State<WorkshopLoginScreen> {
  final id = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> login() async {
    if (id.text.isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your Workshop ID and password.');
      return;
    }
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkshopShell(onThemeChanged: widget.onThemeChanged),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xffffeee8),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        color: Color(0xffff7b45),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'sarathy / workshop',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff11243e),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 58),
                const Text(
                  'Workshop Command',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff11243e),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep every vehicle ready for the road.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 15),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: id,
                  decoration: const InputDecoration(
                    labelText: 'Workshop ID or email',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign in',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      id.text = 'WS-ALV-01';
                      password.text = 'demo';
                      login();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Continue with demo workshop'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to passenger access'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
