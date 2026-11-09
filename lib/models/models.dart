import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;
  final String? fcmToken;
  final String? linkedUid; // set once this contact has linked their own real account
  final String? email; // NEW

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
    this.fcmToken,
    this.linkedUid,
    this.email,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'relation': relation,
    'fcmToken': fcmToken,
    'linkedUid': linkedUid,
    'email': email,
  };
  factory EmergencyContact.fromMap(Map<String, dynamic> m) => EmergencyContact(
    name: m['name'] ?? '',
    phone: m['phone'] ?? '',
    relation: m['relation'] ?? '',
    fcmToken: m['fcmToken'],
    linkedUid: m['linkedUid'],
    email: m['email'],
  );
}

class RideRecord {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final int durationSec;
  final double avgSpeed;
  final double maxSpeed;
  final int safetyScore;
  final List<String> behaviourFlags;
  final String status; // active | completed | crashed

  RideRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    this.distanceKm = 0,
    this.durationSec = 0,
    this.avgSpeed = 0,
    this.maxSpeed = 0,
    this.safetyScore = 100,
    this.behaviourFlags = const [],
    this.status = 'active',
  });

  Map<String, dynamic> toMap() => {
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'distanceKm': distanceKm,
        'durationSec': durationSec,
        'avgSpeed': avgSpeed,
        'maxSpeed': maxSpeed,
        'safetyScore': safetyScore,
        'behaviourFlags': behaviourFlags,
        'status': status,
      };

  factory RideRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return RideRecord(
      id: doc.id,
      startTime: (m['startTime'] as Timestamp).toDate(),
      endTime: (m['endTime'] as Timestamp?)?.toDate(),
      distanceKm: (m['distanceKm'] ?? 0).toDouble(),
      durationSec: m['durationSec'] ?? 0,
      avgSpeed: (m['avgSpeed'] ?? 0).toDouble(),
      maxSpeed: (m['maxSpeed'] ?? 0).toDouble(),
      safetyScore: m['safetyScore'] ?? 100,
      behaviourFlags: List<String>.from(m['behaviourFlags'] ?? []),
      status: m['status'] ?? 'completed',
    );
  }
}

class CrashAlert {
  final String rideId;
  final double lat;
  final double lng;
  final DateTime triggeredAt;
  final String type; // auto_crash | manual_sos
  final String severity; // e.g. "high" based on impact magnitude

  CrashAlert({
    required this.rideId,
    required this.lat,
    required this.lng,
    required this.triggeredAt,
    required this.type,
    this.severity = 'unknown',
  });

  Map<String, dynamic> toMap() => {
        'rideId': rideId,
        'lat': lat,
        'lng': lng,
        'triggeredAt': Timestamp.fromDate(triggeredAt),
        'type': type,
        'severity': severity,
        'resolved': false,
      };
}
