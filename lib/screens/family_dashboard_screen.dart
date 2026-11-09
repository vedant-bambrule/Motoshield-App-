import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class FamilyDashboardScreen extends StatelessWidget {
  const FamilyDashboardScreen({super.key});

  void _showAddContact(BuildContext context, FirestoreService firestore) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add emergency contact',
                style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
                'Add their Gmail so they receive SOS emails automatically.',
                style:
                TextStyle(color: AppColors.textDim, fontSize: 12.5)),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                    hintText: 'Name',
                    hintStyle: TextStyle(color: AppColors.textFaint))),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: AppColors.text),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: AppColors.textFaint))),
            const SizedBox(height: 10),
            TextField(
                controller: emailCtrl,
                style: const TextStyle(color: AppColors.text),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    hintText: 'Gmail address (receives SOS alerts)',
                    hintStyle: TextStyle(color: AppColors.textFaint))),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await firestore.addContact(EmergencyContact(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      relation: 'Family',
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save contact'),
                )),
          ],
        ),
      ),
    );
  }

  void _showMyCode(BuildContext context, FirestoreService firestore) async {
    final code = await firestore.generateLinkCode();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Share this code',
            style: TextStyle(color: AppColors.text)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(code,
              style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 4)),
          const SizedBox(height: 12),
          const Text(
              'Valid for 10 minutes. Have your family member open MOTOSHIELD, sign up or log in, then tap "Enter a code" and type this in.',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: AppColors.textDim, fontSize: 12.5)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done',
                  style: TextStyle(color: AppColors.orange)))
        ],
      ),
    );
  }

  void _showEnterCode(
      BuildContext context, FirestoreService firestore) {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a code',
                style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
                'This links your account so you receive crash/SOS alerts from the rider who shared it.',
                style:
                TextStyle(color: AppColors.textDim, fontSize: 12.5)),
            const SizedBox(height: 16),
            TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    letterSpacing: 2),
                decoration: const InputDecoration(
                    hintText: '123456',
                    hintStyle: TextStyle(color: AppColors.textFaint))),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    try {
                      await firestore
                          .linkAsContactUsingCode(codeCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Linked! You will now get SOS alerts.')));
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(e
                                .toString()
                                .replaceFirst('Exception: ', ''))));
                      }
                    }
                  },
                  child: const Text('Link account'),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Family & emergency contacts',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          const Text(
              'Add their Gmail to receive SOS email alerts automatically. No app needed on their side.',
              style: TextStyle(color: AppColors.textDim, fontSize: 13)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      side: const BorderSide(color: AppColors.lineStrong),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () => _showMyCode(context, firestore),
                  child: const Text('Share my code',
                      style: TextStyle(color: AppColors.text)),
                )),
            const SizedBox(width: 10),
            Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      side: const BorderSide(color: AppColors.lineStrong),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () => _showEnterCode(context, firestore),
                  child: const Text('Enter a code',
                      style: TextStyle(color: AppColors.text)),
                )),
          ]),
          const SizedBox(height: 18),
          StreamBuilder<List<EmergencyContact>>(
            stream: firestore.contacts(),
            builder: (context, snap) {
              final contacts = snap.data ?? [];
              if (contacts.isEmpty) {
                return const AppCard(
                    child: Text('No contacts yet — add one below.',
                        style: TextStyle(color: AppColors.textDim)));
              }
              return Column(
                  children: contacts
                      .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          const CircleAvatar(
                              backgroundColor: AppColors.surface2,
                              child: Icon(Icons.person,
                                  color: AppColors.text, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name,
                                        style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w600)),
                                    if (c.phone.isNotEmpty)
                                      Text(c.phone,
                                          style: const TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 12,
                                              fontFamily: 'monospace')),
                                    if (c.email != null)
                                      Text(c.email!,
                                          style: const TextStyle(
                                              color: AppColors.orange,
                                              fontSize: 11)),
                                  ])),
                          c.email != null
                              ? Pill.green('Email ✓')
                              : Pill.dim('No email'),
                        ])),
                  ))
                      .toList());
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: () => _showAddContact(context, firestore),
              child: const Text('+ Add emergency contact'),
            ),
          ),
        ],
      ),
    );
  }
}