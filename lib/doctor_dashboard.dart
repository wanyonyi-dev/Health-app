import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import './widgets/add_appointment_form.dart';
import './models/appointment.dart'; // Add this import

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Today';
  bool _isLoading = false;
  List<Appointment> _appointments = [];
  DoctorStats _stats = DoctorStats();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAppointments(),
        _fetchDoctorStats(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Error loading dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: _buildDashboardContent(),
          ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dr. ${_auth.currentUser?.displayName ?? "Doctor"}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDate),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _showDatePicker,
          tooltip: 'Select Date',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _showNotifications,
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: _showProfileOptions,
          tooltip: 'Profile',
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(constraints.maxWidth),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Appointment Trends',
                    subtitle: 'Overview of appointment statistics',
                  ),
                  const SizedBox(height: 16),
                  _buildAppointmentChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Appointments'),
                  const SizedBox(height: 8),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  _buildAppointmentsList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCards(double width) {
    // Calculate responsive dimensions
    final crossAxisCount = width > 600 ? 4 : 2;
    final childAspectRatio = width > 600 ? 1.5 : 1.3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          'Today',
          _stats.todayAppointments.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatCard(
          'Pending',
          _stats.pendingAppointments.toString(),
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed',
          _stats.completedAppointments.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Cancelled',
          _stats.cancelledAppointments.toString(),
          Icons.cancel,
          Colors.red,
        ),
      ],
    ).animate().fadeIn().slideY(
      duration: const Duration(milliseconds: 500),
      begin: 0.3,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              _buildChartLegend(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getChartData(),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: Colors.blueGrey.withOpacity(0.2),
                      width: 1,
                    ),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} appointments',
                          TextStyle(
                            color: Colors.blueGrey[800],
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '\nTap for details',
                              style: TextStyle(
                                color: Colors.blueGrey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade().slide();
  }

  Widget _buildChartLegend() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Appointments',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          'Today',
          'Upcoming',
          'Completed',
          'Cancelled',
        ].map((filter) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(filter),
            selected: _selectedFilter == filter,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _filterAppointments();
                });
              }
            },
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            checkmarkColor: Theme.of(context).primaryColor,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming = appointment.dateTime.isAfter(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          Icons.access_time,
                          DateFormat('E, MMM d • hh:mm a').format(appointment.dateTime),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(appointment.status),
                ],
              ),
              if (isUpcoming) const Divider(height: 24),
              if (isUpcoming) Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.check_circle,
                    'Complete',
                    Colors.green,
                    () => _markAppointmentComplete(appointment),
                  ),
                  _buildActionButton(
                    Icons.edit_calendar,
                    'Reschedule',
                    Colors.blue,
                    () => _rescheduleAppointment(appointment),
                  ),
                  _buildActionButton(
                    Icons.cancel,
                    'Cancel',
                    Colors.red,
                    () => _cancelAppointment(appointment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(
      duration: const Duration(milliseconds: 300),
      begin: 0.3,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 16),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no appointments for the selected filter',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddAppointmentDialog(),
      icon: const Icon(Icons.add),
      label: const Text('Add Appointment'),
    );
  }

  // Add supporting methods for functionality
  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterAppointments();
      });
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final snap = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('dateTime')
          .get();

      _appointments = snap.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      _filterAppointments();
    } catch (e) {
      _showErrorSnackBar('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchDoctorStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snap = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .get();

      int todayCount = 0;
      int pendingCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;

      for (var doc in snap.docs) {
        final data = doc.data();
        final appointmentDate = (data['dateTime'] as Timestamp).toDate();
        final status = data['status'] as String;

        if (appointmentDate.isAfter(today) && appointmentDate.isBefore(tomorrow)) {
          todayCount++;
        }

        switch (status.toLowerCase()) {
          case 'pending':
            pendingCount++;
            break;
          case 'completed':
            completedCount++;
            break;
          case 'cancelled':
            cancelledCount++;
            break;
        }
      }

      setState(() {
        _stats = DoctorStats(
          todayAppointments: todayCount,
          pendingAppointments: pendingCount,
          completedAppointments: completedCount,
          cancelledAppointments: cancelledCount,
        );
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching statistics: $e');
    }
  }

  void _filterAppointments() {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final filtered = _appointments.where((appointment) {
        switch (_selectedFilter.toLowerCase()) {
          case 'today':
            return appointment.dateTime.isAfter(today) &&
                appointment.dateTime.isBefore(today.add(const Duration(days: 1)));
          case 'upcoming':
            return appointment.dateTime.isAfter(now) &&
                appointment.status.toLowerCase() == 'pending';
          case 'completed':
            return appointment.status.toLowerCase() == 'completed';
          case 'cancelled':
            return appointment.status.toLowerCase() == 'cancelled';
          default:
            return true;
        }
      }).toList();
      _appointments = filtered;
    });
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Appointment'),
        content: SingleChildScrollView(
          child: AddAppointmentForm(
            onSubmit: (appointment) async {
              await _addAppointment(appointment);
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addAppointment(Appointment appointment) async {
    try {
      await _firestore.collection('appointments').add({
        'doctorId': _auth.currentUser?.uid,
        ...appointment.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _loadDashboardData();
      _showSuccessSnackBar('Appointment added successfully');
    } catch (e) {
      _showErrorSnackBar('Error adding appointment: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                // Add navigation to profile edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add navigation to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _handleSignOut(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Sign out from Firebase
                await _auth.signOut();

                if (!mounted) return;
                
                // Remove loading indicator
                Navigator.pop(context);

                // Navigate to login page and remove all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', // Changed from '/' to '/login'
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error signing out: $e');
    }
  }

  void _showNotifications() {
    // Implement notifications view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon')),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Patient', appointment.patientName),
            _buildDetailItem('Date', DateFormat('MMM dd, yyyy').format(appointment.dateTime)),
            _buildDetailItem('Time', DateFormat('hh:mm a').format(appointment.dateTime)),
            _buildDetailItem('Service', appointment.serviceId),
            _buildDetailItem('Status', appointment.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _markAppointmentComplete(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update({'status': 'completed'});
      
      _loadDashboardData();
      _showSuccessSnackBar('Appointment marked as completed');
    } catch (e) {
      _showErrorSnackBar('Error updating appointment: $e');
    }
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: appointment.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      final TimeOfDay? newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appointment.dateTime),
      );

      if (newTime != null) {
        final DateTime newDateTime = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          newTime.hour,
          newTime.minute,
        );

        try {
          await _firestore.collection('appointments').doc(appointment.id).update({
            'dateTime': Timestamp.fromDate(newDateTime),
            'status': 'pending',
          });

          _loadDashboardData();
          _showSuccessSnackBar('Appointment rescheduled successfully');
        } catch (e) {
          _showErrorSnackBar('Error rescheduling appointment: $e');
        }
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    if (appointment.id == null || appointment.id!.isEmpty) {
      _showErrorSnackBar('Invalid appointment ID');
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await _firestore
            .collection('appointments')
            .doc(appointment.id)
            .update({
              'status': 'cancelled',
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        // Close loading indicator
        if (!mounted) return;
        Navigator.pop(context);
        
        await _loadDashboardData();
        _showSuccessSnackBar('Appointment cancelled successfully');
      } catch (e) {
        // Close loading indicator if there's an error
        if (!mounted) return;
        Navigator.pop(context);
        
        _showErrorSnackBar('Error cancelling appointment: ${e.toString()}');
      }
    }
  }

  List<FlSpot> _getChartData() {
    final List<FlSpot> data = [];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Group appointments by date
    final Map<DateTime, int> appointmentCounts = {};
    for (var appointment in _appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      appointmentCounts[date] = (appointmentCounts[date] ?? 0) + 1;
    }

    // Create data points for the last 7 days
    for (int i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i));
      data.add(FlSpot(
        date.millisecondsSinceEpoch.toDouble(),
        (appointmentCounts[date] ?? 0).toDouble(),
      ));
    }

    return data;
  }
}

// Supporting classes
class DoctorStats {
  final int todayAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;

  DoctorStats({
    this.todayAppointments = 0,
    this.pendingAppointments = 0,
    this.completedAppointments = 0,
    this.cancelledAppointments = 0,
  });
}

// Add this class at the bottom of the file, outside the _DoctorDashboardState class
class TimeSeriesAppointments {
  final DateTime time;
  final int appointments;

  TimeSeriesAppointments(this.time, this.appointments);
}
