import 'package:flutter/material.dart';
import 'package:health_connect/results_screen.dart';
import 'package:health_connect/ai_service.dart';

class StressPredictionScreen extends StatelessWidget {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _stepCountController = TextEditingController();

  StressPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Stress Prediction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _temperatureController,
              decoration: const InputDecoration(labelText: 'Temperature (centigrade)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _stepCountController,
              decoration: const InputDecoration(labelText: 'Step count (last hour)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Parse inputs
                double temperature = double.tryParse(_temperatureController.text) ?? 0.0;
                int stepCount = int.tryParse(_stepCountController.text) ?? 0;

                // Get AI prediction
                String prediction = AiService.predictStress(temperature, stepCount);

                // Navigate to results screen with prediction
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultsScreen(prediction: prediction),
                  ),
                );
              },
              child: const Text('Predict'),
            ),
          ],
        ),
      ),
    );
  }
}
