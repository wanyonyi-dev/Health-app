import 'package:flutter/material.dart';

class MoodLoggingScreen extends StatefulWidget {
  const MoodLoggingScreen({Key? key}) : super(key: key);

  @override
  _MoodLoggingScreenState createState() => _MoodLoggingScreenState();
}

class _MoodLoggingScreenState extends State<MoodLoggingScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedMood;
  double _moodIntensity = 5.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.orangeAccent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.tealAccent, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Mood Log'),
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('How are you feeling today?'),
                const SizedBox(height: 20),
                _buildMoodSelector(),
                const SizedBox(height: 30),
                _buildSectionTitle('How intense is your mood?'),
                _buildIntensitySlider(),
                const SizedBox(height: 30),
                _buildSectionTitle('Notes (optional)'),
                const SizedBox(height: 10),
                _buildNotesField(),
                const SizedBox(height: 30),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.tealAccent),
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: ['😊', '😢', '😠', '😰', '😌'].map((mood) => _buildMoodChip(mood)).toList(),
    );
  }

  Widget _buildMoodChip(String mood) {
    final isSelected = _selectedMood == mood;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        label: Text(mood, style: TextStyle(fontSize: 30)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedMood = selected ? mood : null;
          });
        },
        backgroundColor: isSelected ? Colors.tealAccent.withOpacity(0.3) : Colors.grey[800],
        selectedColor: Colors.tealAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isSelected ? Colors.tealAccent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return Column(
      children: [
        Slider(
          value: _moodIntensity,
          min: 1,
          max: 10,
          divisions: 9,
          label: _moodIntensity.round().toString(),
          onChanged: (value) {
            setState(() {
              _moodIntensity = value;
            });
          },
          activeColor: Colors.orangeAccent,
          inactiveColor: Colors.orangeAccent.withOpacity(0.3),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low', style: TextStyle(color: Colors.grey[400])),
            Text('High', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Add any additional notes here...',
        filled: true,
        fillColor: Colors.grey[800],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _validateAndSaveMoodEntry,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Save Entry', style: TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.tealAccent, shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  void _validateAndSaveMoodEntry() {
    if (_selectedMood == null) {
      _showErrorSnackBar('Please select a mood before saving.');
      return;
    }

    final moodEntry = {
      'mood': _selectedMood,
      'intensity': _moodIntensity,
      'notes': _notesController.text,
      'timestamp': DateTime.now(),
    };

    // Here you would typically save the mood entry to a database or local storage

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mood Entry Saved', style: TextStyle(color: Colors.tealAccent)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mood: $_selectedMood', style: TextStyle(fontSize: 18)),
            Text('Intensity: ${_moodIntensity.round()}', style: TextStyle(fontSize: 18)),
            if (_notesController.text.isNotEmpty)
              Text('Notes: ${_notesController.text}', style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: Text('OK', style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedMood = null;
      _moodIntensity = 5.0;
      _notesController.clear();
    });
  }
}