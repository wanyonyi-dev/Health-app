import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionUtils {
  static final Map<String, _SessionTime> sessionTimes = {
    'Morning (8:00 AM - 1:00 PM)': _SessionTime(
      start: TimeOfDay(hour: 8, minute: 0),
      end: TimeOfDay(hour: 13, minute: 0),
    ),
    'Afternoon (2:00 PM - 4:00 PM)': _SessionTime(
      start: TimeOfDay(hour: 14, minute: 0),
      end: TimeOfDay(hour: 16, minute: 0),
    ),
  };

  static bool isSessionAvailable(String session, DateTime selectedDate) {
    final now = DateTime.now();
    final sessionTime = sessionTimes[session];
    
    if (sessionTime == null) return false;

    // If selected date is in the future, session is available
    if (selectedDate.isAfter(DateTime(now.year, now.month, now.day))) {
      return true;
    }

    // If selected date is today, check session time
    if (selectedDate.year == now.year && 
        selectedDate.month == now.month && 
        selectedDate.day == now.day) {
      final currentTime = TimeOfDay.now();
      return !_isTimeAfter(currentTime, sessionTime.end);
    }

    return false;
  }

  static bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour || 
           (time1.hour == time2.hour && time1.minute > time2.minute);
  }
}

class _SessionTime {
  final TimeOfDay start;
  final TimeOfDay end;

  _SessionTime({required this.start, required this.end});
}