import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_zrbqkfa';
  static const String _templateId = 'template_alzjjej';
  static const String _publicKey = 'BjBUA7XbjI8rKPX3s';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static Future<bool> sendSosAlert({
    required String riderName,
    required String contactName,
    required String contactEmail,
    required double lat,
    required double lng,
    required String alertType,
  }) async {
    try {
      final locationLink =
          'https://www.google.com/maps?q=$lat,$lng';
      final time = DateTime.now().toString().substring(0, 19);
      final alertText = alertType == 'auto_crash'
          ? '🚨 A possible crash has been automatically detected based on sensor data.'
          : '🆘 The rider has manually triggered an SOS alert.';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': contactEmail,
            'rider_name': riderName,
            'contact_name': contactName,
            'alert_type': alertText,
            'time': time,
            'location_link': locationLink,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('EMAIL SENT to $contactEmail');
        return true;
      } else {
        print('EMAIL FAILED: ${response.statusCode} — ${response.body}');
        return false;
      }
    } catch (e) {
      print('EMAIL ERROR: $e');
      return false;
    }
  }
}