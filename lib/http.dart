import 'dart:convert';
import 'package:http/http.dart' as http;

void _sendNotification(Map<String, String> appointmentDetails) async {
  const String url = 'https://<your-cloud-function-url>'; // Replace with your Cloud Function URL
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(appointmentDetails),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification');
  }
}
