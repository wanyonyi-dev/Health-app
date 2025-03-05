import 'package:flutter/material.dart';

import 'stress_prediction_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    "Do you feel constantly on guard, watchful, or easily startled?",
    "Do you often feel nervous or on edge?",
    "Do you find it hard to concentrate on tasks?"
    // Add more questions as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaire'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question no - ${_currentQuestionIndex + 1}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              _questions[_currentQuestionIndex],
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_currentQuestionIndex < _questions.length - 1) {
                        _currentQuestionIndex++;
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StressPredictionScreen()),
                        );
                      }
                    });
                  },
                  child: const Text('Yes'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_currentQuestionIndex < _questions.length - 1) {
                        _currentQuestionIndex++;
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StressPredictionScreen()),
                        );
                      }
                    });
                  },
                  child: const Text('No'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
