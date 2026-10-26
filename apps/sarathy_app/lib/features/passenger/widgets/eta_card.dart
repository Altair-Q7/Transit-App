import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../core/utils/app_utils.dart';

/// Mirrors the "Passenger Intelligence" mockup: location, live ETA +
/// confidence, and an on-time/delayed status chip.
///
/// The API reports status as one of: `en_route`, `departed`,
/// `no_live_data`. Anything else is treated as unknown.
class EtaCard extends StatelessWidget {
  const EtaCard({super.key, required this.stopName, required this.estimate});

  final String stopName;
  final EtaEstimate estimate;

  Color get _statusColor {
    switch (estimate.status) {
      case 'en_route':
        return const Color(0xFF4C7A5E);
      case 'departed':
        return const Color(0xFF6B7C86);
      case 'no_live_data':
        return const Color(0xFFC97B4A);
      default:
        return const Color(0xFF6B7C86);
    }
  }

  String get _statusLabel {
    switch (estimate.status) {
      case 'en_route':
        return 'Status: On the way';
      case 'departed':
        return 'Status: Departed';
      case 'no_live_data':
        return 'Status: No live data';
      default:
        return 'Status: Unknown';
    }
  }

  String get _etaText {
    if (estimate.status == 'no_live_data') {
      return 'Live ETA: awaiting live data';
    }
    return 'Live ETA: ${estimate.etaMinutes.round()} mins  •  Confidence: ${formatConfidence(estimate.confidence)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFC9D3D6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: $stopName', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_etaText),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(_statusLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
