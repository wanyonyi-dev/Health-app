import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  final List<Map<String, String>> emergencyHospitals = [
    {'county': 'Nairobi County', 'hospital': 'Kijabe Hosp', 'phone': 'tel:+254711000001'},
    {'county': 'Nakuru County', 'hospital': 'Kabarak Hosp', 'phone': 'tel:+254711000002'},
    {'county': 'Baringo County', 'hospital': 'Mercy Hosp', 'phone': 'tel:+254711000003'},
    {'county': 'Mombasa County', 'hospital': 'Mediheal Hosp', 'phone': 'tel:+254711000004'},
    {'county': 'Nairobi County', 'hospital': 'Kijabe Hosp', 'phone': 'tel:+254711000005'},
    {'county': 'Mombasa County', 'hospital': 'Kibaki Hosp', 'phone': 'tel:+254711000006'},
    {'county': 'Turkana County', 'hospital': 'Mwanga Hosp', 'phone': 'tel:+254711000007'},
    {'county': 'Bomet County', 'hospital': 'Whales Hosp', 'phone': 'tel:+254711000008'},
  ];

  EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          itemCount: emergencyHospitals.length,
          itemBuilder: (context, index) {
            final hospital = emergencyHospitals[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(
                  '${hospital['hospital']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${hospital['county']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(hospital['phone']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text('CALL', style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
