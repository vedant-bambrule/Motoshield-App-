import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../services/location_service.dart';
import '../models/models.dart';

enum _Stage { idle, countdown, sent }

class SosScreen extends StatefulWidget {
  final bool autoTriggered;
  final String? rideId;
  final double impactMagnitude;

  const SosScreen({
    super.key,
    this.autoTriggered = false,
    this.rideId,
    this.impactMagnitude = 0,
  });

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _firestore = FirestoreService();
  final _location = LocationService();

  late _Stage stage =
  widget.autoTriggered ? _Stage.countdown : _Stage.idle;
  int countdown = 15;
  Timer? _timer;
  bool _sending = false;
  bool _sent = false;
  int _emailsSent = 0;

  @override
  void initState() {
    super.initState();
    if (stage == _Stage.countdown) _runCountdown();
  }

  void _startCountdown() {
    setState(() => stage = _Stage.countdown);
    countdown = 15;
    _runCountdown();
  }

  void _runCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (countdown <= 1) {
        t.cancel();
        await _sendAlert();
      } else {
        setState(() => countdown--);
      }
    });
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      stage = _Stage.idle;
      countdown = 15;
    });
  }

  Future<void> _sendAlert() async {
    setState(() {
      _sending = true;
      stage = _Stage.sent;
    });

    try {
      // Step 1 — get GPS location
      Position pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

      // Step 2 — save alert to Firestore
      await _firestore.raiseAlert(CrashAlert(
        rideId: widget.rideId ?? 'manual',
        lat: pos.latitude,
        lng: pos.longitude,
        triggeredAt: DateTime.now(),
        type: widget.autoTriggered ? 'auto_crash' : 'manual_sos',
        severity: widget.impactMagnitude > 40 ? 'high' : 'medium',
      ));

      print('MOTOSHIELD: Alert saved to Firestore ✓');

      // Step 3 — send email to every contact that has an email
      final riderName = await _firestore.getRiderName();
      final contacts = await _firestore.getContactsForAlert();

      if (contacts.isEmpty) {
        print('MOTOSHIELD: No email contacts found — '
            'add a Gmail address to a contact in the Family tab');
      }

      int sent = 0;
      for (final contact in contacts) {
        final success = await EmailService.sendSosAlert(
          riderName: riderName,
          contactName: contact.name,
          contactEmail: contact.email!,
          lat: pos.latitude,
          lng: pos.longitude,
          alertType: widget.autoTriggered ? 'auto_crash' : 'manual_sos',
        );
        if (success) {
          sent++;
          print('MOTOSHIELD: EMAIL SENT ✓ → ${contact.name} (${contact.email})');
        } else {
          print('MOTOSHIELD: EMAIL FAILED ✗ → ${contact.name}');
        }
      }

      setState(() {
        _sent = true;
        _emailsSent = sent;
      });
    } catch (e) {
      print('MOTOSHIELD: SOS ERROR — $e');
      setState(() => _sent = false);
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          children: [
            const Center(child: Eyebrow('Emergency')),
            const SizedBox(height: 6),
            Center(
              child: Text(
                stage == _Stage.sent ? 'Alert sent' : 'Emergency SOS',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
            ),
            const SizedBox(height: 28),

            if (stage != _Stage.sent) ...[
              Center(
                child: GestureDetector(
                  onTap: stage == _Stage.countdown
                      ? _cancel
                      : _startCountdown,
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.red),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.campaign_outlined,
                            color: Colors.black, size: 34),
                        const SizedBox(height: 10),
                        Text(
                          stage == _Stage.countdown
                              ? 'Cancel ($countdown)'
                              : 'Tap to trigger',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.autoTriggered
                      ? "Our sensors think you may have crashed. If you're okay, cancel now."
                      : stage == _Stage.countdown
                      ? 'Sending your location to emergency contacts. Tap to cancel.'
                      : 'Tap if you feel unsafe. Your GPS location will be emailed to your emergency contacts.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDim),
                ),
              ),
            ] else ...[
              AppCard(
                borderColor: AppColors.red,
                child: Column(
                  children: [
                    _sending
                        ? const Pill(
                        text: 'Sending alert…',
                        color: AppColors.textDim,
                        bg: AppColors.surface2)
                        : _sent
                        ? Pill.green(
                        _emailsSent > 0
                            ? 'Alert sent — $_emailsSent contact(s) emailed'
                            : 'Saved — add a Gmail to contacts for email alerts')
                        : Pill.red(
                        'Could not send — check location permission'),
                    const SizedBox(height: 10),
                    Text(
                      _emailsSent > 0
                          ? 'Your emergency contact(s) have been emailed your GPS location.'
                          : 'Your alert is saved. Add a Gmail address to a contact in the Family tab to enable email alerts.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      side: const BorderSide(color: AppColors.lineStrong),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text("I'm safe — close alert",
                      style: TextStyle(color: AppColors.text)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}