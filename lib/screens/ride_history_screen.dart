import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return StreamBuilder<List<RideRecord>>(
      stream: firestore.rideHistory(),
      builder: (context, snap) {
        final rides = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Ride history', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 18),
            if (rides.isEmpty)
              const AppCard(child: Text('No rides recorded yet.', style: TextStyle(color: AppColors.textDim))),
            ...rides.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(padding: const EdgeInsets.all(14), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${r.startTime.day}/${r.startTime.month} · ${r.startTime.hour}:${r.startTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                    r.status == 'crashed' ? Pill.red('Crashed') : (r.safetyScore >= 85 ? Pill.green('${r.safetyScore}') : Pill.orange('${r.safetyScore}')),
                  ]),
                  const SizedBox(height: 8),
                  Text('${r.distanceKm.toStringAsFixed(1)} km · ${(r.durationSec / 60).toStringAsFixed(0)} min · max ${r.maxSpeed.toStringAsFixed(0)} km/h',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12.5)),
                  if (r.behaviourFlags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: r.behaviourFlags.map((f) => Pill.orange(f)).toList()),
                  ],
                ],
              )),
            )),
          ],
        );
      },
    );
  }
}
