import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get riderDoc =>
      _db.collection('riders').doc(_uid);

  Stream<Map<String, dynamic>> riderProfile() =>
      riderDoc.snapshots().map((d) => d.data() ?? {});

  Stream<List<EmergencyContact>> contacts() {
    return riderDoc.collection('contacts').snapshots().map(
          (snap) => snap.docs
          .map((d) => EmergencyContact.fromMap(d.data()))
          .toList(),
    );
  }

  Future<void> addContact(EmergencyContact c) {
    return riderDoc.collection('contacts').add(c.toMap());
  }

  Future<DocumentReference<Map<String, dynamic>>> startRide() {
    return riderDoc.collection('rides').add(
      RideRecord(id: '', startTime: DateTime.now(), status: 'active')
          .toMap(),
    );
  }

  Future<void> updateRideTelemetry(String rideId,
      {required double distanceKm,
        required int durationSec,
        required double avgSpeed,
        required double maxSpeed}) {
    return riderDoc.collection('rides').doc(rideId).update({
      'distanceKm': distanceKm,
      'durationSec': durationSec,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
    });
  }

  Future<void> endRide(String rideId,
      {required int safetyScore,
        required List<String> flags,
        String status = 'completed'}) {
    return riderDoc.collection('rides').doc(rideId).update({
      'endTime': Timestamp.now(),
      'safetyScore': safetyScore,
      'behaviourFlags': flags,
      'status': status,
    });
  }

  Stream<List<RideRecord>> rideHistory() {
    return riderDoc
        .collection('rides')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RideRecord.fromDoc(d)).toList());
  }

  Future<void> raiseAlert(CrashAlert alert) async {
    await riderDoc.collection('alerts').add(alert.toMap());
    if (alert.type == 'auto_crash') {
      await riderDoc
          .collection('rides')
          .doc(alert.rideId)
          .update({'status': 'crashed'});
    }
  }

  Future<void> saveFcmToken(String token) async {
    final snap = await riderDoc.get();
    if (snap.exists) {
      await riderDoc.update({'fcmToken': token});
    }
  }

  // Get all contacts that have an email — used for SOS email alerts
  Future<List<EmergencyContact>> getContactsForAlert() async {
    final snap = await riderDoc.collection('contacts').get();
    final all = snap.docs
        .map((d) => EmergencyContact.fromMap(d.data()))
        .toList();

    print('CONTACTS TOTAL: ${all.length}');
    for (final c in all) {
      print('  - ${c.name} | email: ${c.email} | linked: ${c.linkedUid}');
    }

    final withEmail = all.where((c) =>
    c.email != null && c.email!.isNotEmpty).toList();
    print('CONTACTS WITH EMAIL: ${withEmail.length}');
    return withEmail;
  }

  // Get rider's display name for the email
  Future<String> getRiderName() async {
    final doc = await riderDoc.get();
    return doc.data()?['name'] ?? 'Your rider';
  }

  Future<String> generateLinkCode() async {
    final code = (100000 + Random().nextInt(900000)).toString();
    await _db.collection('linkCodes').doc(code).set({
      'ownerUid': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10))),
    });
    return code;
  }

  Future<void> linkAsContactUsingCode(String code) async {
    final codeDoc = await _db.collection('linkCodes').doc(code).get();
    if (!codeDoc.exists) throw Exception('Invalid code — ask the rider to generate a new one');

    final data = codeDoc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('That code expired — ask for a new one');
    }

    final ownerUid = data['ownerUid'] as String;
    if (ownerUid == _uid) throw Exception("You can't link to yourself");

    // Get this person's profile — name AND email from their account
    final myProfile = await riderDoc.get();
    final myName = myProfile.data()?['name'] ?? 'Family member';
    final myEmail = myProfile.data()?['email']
        ?? FirebaseAuth.instance.currentUser?.email
        ?? '';

    // Write contact entry under the RIDER's contacts
    // Doc ID = this person's uid so it's easy to find later
    await _db
        .collection('riders')
        .doc(ownerUid)
        .collection('contacts')
        .doc(_uid)
        .set({
      'name': myName,
      'phone': '',
      'relation': 'Family',
      'linkedUid': _uid,
      'email': myEmail,
      'fcmToken': null,
    });

    // Mark the code as used so it can't be reused
    await _db.collection('linkCodes').doc(code).delete();
  }
}