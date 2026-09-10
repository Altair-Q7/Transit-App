import 'package:flutter/material.dart';
import 'crew_shell.dart';

class CrewLoginScreen extends StatefulWidget {
  const CrewLoginScreen({super.key, this.onThemeChanged});
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override
  State<CrewLoginScreen> createState() => _CrewLoginScreenState();
}

class _CrewLoginScreenState extends State<CrewLoginScreen> {
  final id = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> login() async {
    if (id.text.isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your Crew ID and password.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CrewShell(onThemeChanged: widget.onThemeChanged),
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
                      'sarathy / crew',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff11243e),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 58),
                const Text(
                  'Crew Command',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff11243e),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep every trip moving safely and on time.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 15),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: id,
                  decoration: const InputDecoration(
                    labelText: 'Crew ID or phone',
                    prefixIcon: Icon(Icons.badge_outlined),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Checkbox(value: true, onChanged: null),
                    const Text('Remember me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign in',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      id.text = 'CRW-042';
                      password.text = 'demo';
                      login();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Continue with demo crew'),
                  ),
                ),
                const SizedBox(height: 22),
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
