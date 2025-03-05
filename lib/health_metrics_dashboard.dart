import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HealthMetric {
  final String value;
  final String unit;
  final String trend;
  final DateTime timestamp;

  HealthMetric({
    required this.value,
    required this.unit,
    required this.trend,
    required this.timestamp,
  });

  factory HealthMetric.fromFirestore(Map<String, dynamic> data) {
    return HealthMetric(
      value: data['value'].toString(),
      unit: data['unit'] ?? '',
      trend: data['trend'] ?? '0',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class HealthMetricsDashboard extends StatefulWidget {
  final String userId;

  const HealthMetricsDashboard({
    super.key,
    required this.userId,
  });

  @override
  State<HealthMetricsDashboard> createState() => _HealthMetricsDashboardState();
}

class _HealthMetricsDashboardState extends State<HealthMetricsDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedPeriod = 'Week';
  String selectedMetric = 'Heart Rate'; // Changed from 'All' to 'Heart Rate'
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot>? _metricsStream;
  Map<String, HealthMetric> currentMetrics = {};
  List<Map<String, dynamic>> historicalData = [];

  final List<String> metrics = [
    'Heart Rate',
    'Steps',
    'Sleep',
    'Calories',
    'Weight',
    'Blood Pressure',
    'Blood Sugar',
    'Active Minutes',
  ];

  final List<String> periods = ['Day', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeDataStream();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeDataStream() {
    final DateTime periodStart = _getPeriodStartDate();

    _metricsStream = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('health_metrics')
        .where('timestamp', isGreaterThanOrEqualTo: periodStart)
        .orderBy('timestamp', descending: true)
        .snapshots();

    _loadHistoricalData();
  }

  DateTime _getPeriodStartDate() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'Day':
        return DateTime(now.year, now.month, now.day);
      case 'Week':
        return now.subtract(const Duration(days: 7));
      case 'Month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'Year':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('health_metrics')
          .where('timestamp', isGreaterThanOrEqualTo: _getPeriodStartDate())
          .orderBy('timestamp')
          .get();

      historicalData = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading historical data: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _metricsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final metricType = data['type'] as String;
                currentMetrics[metricType] = HealthMetric.fromFirestore(data);
              }
            }

            return RefreshIndicator(
              onRefresh: _loadHistoricalData,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDashboardContent(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            const SizedBox(height: 20),
            _buildMetricsOverview(),
            const SizedBox(height: 24),
            _buildTrendsChart(),
            const SizedBox(height: 24),
            _buildHealthGoals(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Health Metrics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          items: periods.map((period) => DropdownMenuItem(
            value: period,
            child: Text(period),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedPeriod = value;
                _initializeDataStream();
              });
            }
          },
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final metrics = [
      MetricCard(
        icon: LucideIcons.heart,
        title: 'Heart Rate',
        value: _getMetricValue('heart_rate', '0'),
        unit: 'bpm',
        trend: _getMetricTrend('heart_rate', '0'),
        color: const Color(0xFFEF4444),
      ),
      MetricCard(
        icon: LucideIcons.footprints,
        title: 'Steps',
        value: _getMetricValue('steps', '0'),
        unit: 'steps',
        trend: _getMetricTrend('steps', '0'),
        color: const Color(0xFF3B82F6),
      ),
      MetricCard(
        icon: LucideIcons.bed,
        title: 'Sleep',
        value: _getMetricValue('sleep', '0'),
        unit: 'hours',
        trend: _getMetricTrend('sleep', '0'),
        color: const Color(0xFF8B5CF6),
      ),
      MetricCard(
        icon: LucideIcons.flame,
        title: 'Calories',
        value: _getMetricValue('calories', '0'),
        unit: 'kcal',
        trend: _getMetricTrend('calories', '0'),
        color: const Color(0xFFF59E0B),
      ),
      MetricCard(
        icon: LucideIcons.scale,
        title: 'Weight',
        value: _getMetricValue('weight', '0'),
        unit: 'kg',
        trend: _getMetricTrend('weight', '0'),
        color: const Color(0xFF14B8A6),
      ),
      MetricCard(
        icon: LucideIcons.activity,
        title: 'Blood Pressure',
        value: _getMetricValue('blood_pressure', '0/0'),
        unit: 'mmHg',
        trend: _getMetricTrend('blood_pressure', '0'),
        color: const Color(0xFFEC4899),
      ),
      MetricCard(
        icon: LucideIcons.droplets,
        title: 'Blood Sugar',
        value: _getMetricValue('blood_sugar', '0'),
        unit: 'mg/dL',
        trend: _getMetricTrend('blood_sugar', '0'),
        color: const Color(0xFF6366F1),
      ),
      MetricCard(
        icon: LucideIcons.dumbbell,
        title: 'Active Minutes',
        value: _getMetricValue('active_minutes', '0'),
        unit: 'min',
        trend: _getMetricTrend('active_minutes', '0'),
        color: const Color(0xFF84CC16),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.3,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }

  String _getMetricValue(String metricType, String defaultValue) {
    return currentMetrics[metricType]?.value ?? defaultValue;
  }

  String _getMetricTrend(String metricType, String defaultValue) {
    return currentMetrics[metricType]?.trend ?? defaultValue;
  }

  Widget _buildTrendsChart() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                _buildMetricSelector(),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                _createChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMetric,
          items: metrics.map((metric) => DropdownMenuItem(
            value: metric,
            child: Text(metric),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedMetric = value);
            }
          },
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  LineChartData _createChartData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: _createChartTitles(),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _getChartSpots(),
          isCurved: true,
          color: _getMetricColor(selectedMetric),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _getMetricColor(selectedMetric).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getChartSpots() {
    if (historicalData.isEmpty) return [];

    final List<FlSpot> spots = [];
    final String metricType = _getMetricTypeFromSelection();

    for (int i = 0; i < historicalData.length; i++) {
      final data = historicalData[i];
      if (data.containsKey(metricType)) {
        spots.add(FlSpot(i.toDouble(), double.parse(data[metricType].toString())));
      }
    }

    return spots;
  }

  String _getMetricTypeFromSelection() {
    switch (selectedMetric) {
      case 'Heart Rate':
        return 'heart_rate';
      case 'Steps':
        return 'steps';
      case 'Sleep':
        return 'sleep';
      case 'Calories':
        return 'calories';
      case 'Weight':
        return 'weight';
      case 'Blood Pressure':
        return 'blood_pressure';
      case 'Blood Sugar':
        return 'blood_sugar';
      case 'Active Minutes':
        return 'active_minutes';
      default:
        return 'heart_rate';
    }
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'Heart Rate':
        return const Color(0xFFEF4444);
      case 'Steps':
        return const Color(0xFF3B82F6);
      case 'Sleep':
        return const Color(0xFF8B5CF6);
      case 'Calories':
        return const Color(0xFFF59E0B);
      case 'Weight':
        return const Color(0xFF14B8A6);
      case 'Blood Pressure':
        return const Color(0xFFEC4899);
      case 'Blood Sugar':
        return const Color(0xFF6366F1);
      case 'Active Minutes':
        return const Color(0xFF84CC16);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  FlTitlesData _createChartTitles() {
    return FlTitlesData(
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (historicalData.isEmpty || value.toInt() >= historicalData.length) {
              return const SizedBox();
            }

            final data = historicalData[value.toInt()];
            final date = (data['timestamp'] as Timestamp).toDate();

            String text;
            switch (selectedPeriod) {
              case 'Day':
                text = DateFormat('HH:mm').format(date);
                break;
              case 'Week':
                text = DateFormat('E').format(date);
                break;
              case 'Month':
                text = DateFormat('d MMM').format(date);
                break;
              case 'Year':
                text = DateFormat('MMM').format(date);
                break;
              default:
                text = DateFormat('E').format(date);
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHealthGoals() {
    final goals = [
      _buildGoalProgress(
        'Daily Steps',
        _calculateProgress('steps', 10000),
        '${_getMetricValue('steps', '0')} / 10,000 steps',
        const Color(0xFF3B82F6),
      ),
      _buildGoalProgress(
        'Sleep Duration',
        _calculateProgress('sleep', 8),
        '${_getMetricValue('sleep', '0')} / 8 hours',
        const Color(0xFF8B5CF6),
      ),
      _buildGoalProgress(
        'Calories Burned',
        _calculateProgress('calories', 2500),
        '${_getMetricValue('calories', '0')} / 2,500 kcal',
        const Color(0xFFF59E0B),
      ),
      _buildGoalProgress(
        'Active Minutes',
        _calculateProgress('active_minutes', 30),
        '${_getMetricValue('active_minutes', '0')} / 30 min',
        const Color(0xFF84CC16),
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Health Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: goal,
            )).toList(),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(String metricType, double goal) {
    final currentValue = double.tryParse(_getMetricValue(metricType, '0')) ?? 0;
    return (currentValue / goal).clamp(0.0, 1.0);
  }

  Widget _buildGoalProgress(
      String title,
      double progress,
      String status,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String trend;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend != '0')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trend.startsWith('+')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        color: trend.startsWith('+')
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}