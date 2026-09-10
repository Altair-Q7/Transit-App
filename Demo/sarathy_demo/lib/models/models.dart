import 'package:flutter/material.dart';

enum BusStatus { onTime, approaching, delayed, stopped, disruption }

enum ConnectionStateDemo { online, weak, offline, reconnecting }

class DemoLocation {
  const DemoLocation(this.name, this.code, this.subtitle, this.color);
  final String name, code, subtitle;
  final Color color;
}

class DemoBus {
  DemoBus({
    required this.id,
    required this.route,
    required this.destination,
    required this.eta,
    required this.speed,
    required this.status,
    required this.confidence,
    required this.nextStop,
    required this.stopsRemaining,
    required this.color,
    this.progress = .58,
  });
  final String id, route, destination, eta, nextStop;
  final double speed, confidence;
  final BusStatus status;
  final int stopsRemaining;
  final Color color;
  double progress;
}

class DemoStop {
  const DemoStop(this.name, this.distance, this.buses, this.eta, this.area);
  final String name, distance, buses, eta, area;
}

class DemoNotification {
  const DemoNotification(
    this.title,
    this.body,
    this.time,
    this.icon,
    this.color, {
    this.unread = true,
  });
  final String title, body, time;
  final IconData icon;
  final Color color;
  final bool unread;
}
