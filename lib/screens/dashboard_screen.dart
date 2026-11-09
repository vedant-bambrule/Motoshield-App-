import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'Rider';

    return StreamBuilder<Map<String, dynamic>>(
      stream: firestore.riderProfile(),
      builder: (context, profileSnap) {
        final safetyScore = profileSnap.data?['safetyScore'] ?? 100;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('Good to see you'),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
              ]),
              const CircleAvatar(backgroundColor: AppColors.surface2, child: Icon(Icons.person, color: AppColors.text)),
            ]),
            const SizedBox(height: 22),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text('$safetyScore', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.orange)),
                const Eyebrow('Safety score · from real ride data'),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Recent rides', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 12),
            StreamBuilder<List<RideRecord>>(
              stream: firestore.rideHistory(),
              builder: (context, snap) {
                final rides = (snap.data ?? []).take(3).toList();
                if (rides.isEmpty) {
                  return const AppCard(child: Text('No rides yet — start one from the Ride tab.', style: TextStyle(color: AppColors.textDim)));
                }
                return Column(
                  children: rides.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(padding: const EdgeInsets.all(14), child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${r.distanceKm.toStringAsFixed(1)} km · ${(r.durationSec / 60).toStringAsFixed(0)} min',
                            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                        r.status == 'crashed' ? Pill.red('Crashed') : Pill.green('${r.safetyScore}'),
                      ],
                    )),
                  )).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
