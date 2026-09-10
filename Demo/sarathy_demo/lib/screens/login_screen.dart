import 'package:flutter/material.dart';
import 'crew_login_screen.dart';
import 'workshop_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin, this.onThemeChanged});
  final void Function(BuildContext) onLogin;
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false, remember = true, obscure = true;
  String? error;
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your email or phone and password.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) widget.onLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff11243e);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
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
                        'sarathy',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your smarter way to move around Kerala.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 15),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'Email or phone',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: remember,
                            onChanged: (v) =>
                                setState(() => remember = v ?? true),
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign in',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        email.text = 'demo@sarathy.app';
                        password.text = 'demo';
                        login();
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Continue with demo account'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CrewLoginScreen(
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.drive_eta_rounded, size: 17),
                      label: const Text('Crew access'),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkshopLoginScreen(
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.build_circle_outlined, size: 17),
                      label: const Text('Workshop access'),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Passenger access  •  Demo environment',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
