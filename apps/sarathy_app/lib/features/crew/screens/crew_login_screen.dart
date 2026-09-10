import 'package:flutter/material.dart';
import '../../../../services.dart';
import '../../../../models.dart';
import '../../../../features.dart';

class CrewLoginScreen extends StatefulWidget {
  const CrewLoginScreen({super.key});

  @override
  State<CrewLoginScreen> createState() => _CrewLoginScreenState();
}

class _CrewLoginScreenState extends State<CrewLoginScreen> {
  final _api = ApiService();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tokens = await _api.crewLogin(CrewCredentials(
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
      ));
      await AuthService.saveCrewSession(tokens);
      CrewSession.setSession(
        token: tokens.accessToken,
        crewId: 0, // TODO: decode from JWT or fetch from API
        operatorId: 0,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('crewTripControl');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sarathy Crew')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const CircularProgressIndicator() : const Text('Sign in'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('roleSelection'),
              child: const Text('Back to role selection'),
            ),
          ],
        ),
      ),
    );
  }
}