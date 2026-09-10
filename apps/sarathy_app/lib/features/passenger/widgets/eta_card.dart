import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../../core/utils/app_utils.dart';

/// Mirrors the "Passenger Intelligence" mockup: location, live ETA +
/// confidence, and an on-time/delayed status chip.
class EtaCard extends StatelessWidget {
  const EtaCard({super.key, required this.stopName, required this.estimate});

  final String stopName;
  final EtaEstimate estimate;

  Color get _statusColor => estimate.status == 'on_time'
      ? const Color(0xFF4C7A5E)
      : const Color(0xFFC97B4A);

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
            Text(
              'Live ETA: ${estimate.etaMinutes.round()} mins  •  Confidence: ${formatConfidence(estimate.confidence)}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(estimate.status == 'on_time' ? 'Status: On Time' : 'Status: Delayed'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}