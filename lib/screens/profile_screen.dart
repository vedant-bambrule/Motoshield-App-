import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [
          const CircleAvatar(radius: 26, backgroundColor: AppColors.surface2, child: Icon(Icons.person, color: AppColors.text)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.displayName ?? 'Rider', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            Text(user?.email ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(backgroundColor: AppColors.surface2, side: const BorderSide(color: AppColors.lineStrong), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            }
          },
          icon: const Icon(Icons.logout, size: 16, color: AppColors.text),
          label: const Text('Log out', style: TextStyle(color: AppColors.text)),
        )),
      ],
    );
  }
}
