import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMetricDialog extends StatefulWidget {
  final String userId;
  final String metricType;
  final String unit;

  const AddMetricDialog({
    super.key,
    required this.userId,
    required this.metricType,
    required this.unit,
  });

  @override
  State<AddMetricDialog> createState() => _AddMetricDialogState();
}

class _AddMetricDialogState extends State<AddMetricDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveMetric() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final value = double.parse(_valueController.text);
      final previousMetric = await _getPreviousMetric();
      final trend = previousMetric != null
          ? _calculateTrend(value, previousMetric)
          : '0';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('health_metrics')
          .add({
        'type': widget.metricType,
        'value': value,
        'unit': widget.unit,
        'trend': trend,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<double?> _getPreviousMetric() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('health_metrics')
          .where('type', isEqualTo: widget.metricType)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return double.parse(snapshot.docs.first['value'].toString());
      }
    } catch (e) {
      print('Error getting previous metric: $e');
    }
    return null;
  }

  String _calculateTrend(double currentValue, double previousValue) {
    final difference = currentValue - previousValue;
    final percentageChange = (difference / previousValue * 100).toStringAsFixed(1);
    return difference >= 0 ? '+$percentageChange%' : '$percentageChange%';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.metricType} Measurement'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _valueController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Value',
            suffix: Text(widget.unit),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveMetric,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}