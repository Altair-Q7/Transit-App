import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Entry point for the Sarathy app - role selection screen.
/// Users choose whether they are a Passenger, Crew, or Operator.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Title
              Icon(
                Icons.directions_bus,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 48),

              // Role selection cards
              _RoleCard(
                icon: Icons.person,
                title: 'Passenger',
                subtitle: 'Find stops, check ETAs, track buses',
                color: Colors.blue,
                onTap: () => Navigator.of(context).pushReplacementNamed('passengerHome'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.drive_eta,
                title: 'Crew',
                subtitle: 'Start trips, report GPS, log incidents',
                color: Colors.orange,
                onTap: () => Navigator.of(context).pushReplacementNamed('crewLogin'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.admin_panel_settings,
                title: 'Operator',
                subtitle: 'Manage fleet, routes, monitor operations',
                color: Colors.green,
                onTap: () => Navigator.of(context).pushReplacementNamed('operatorLogin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}