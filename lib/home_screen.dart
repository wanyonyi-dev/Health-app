import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:health_connect/screens/health_chat_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:health_connect/health_metrics_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import './providers/appointment_cart_provider.dart';
import './models/appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userId});
  final String userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _menuController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _menuController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: Theme.of(context).copyWith(
          primaryColor: const Color(0xFF1E293B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E293B),
            secondary: const Color(0xFF3B82F6),
            tertiary: const Color(0xFF10B981),
          ),
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: _buildDrawer(context),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(context),
              _buildWelcomeMessage(context),
              _buildQuickActions(context),
              _buildUpcomingAppointments(context),
              _buildMainServices(context),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context),
          floatingActionButton: _buildEmergencyFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF3B82F6).withOpacity(0.9),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(LucideIcons.user, color: const Color(0xFF1E293B), size: 40),
              ),
              accountName: const Text(
                'Patient Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            _buildDrawerItem(LucideIcons.settings, 'Settings', () {
              Navigator.pushNamed(context, '/settings');
            }),
            _buildDrawerItem(LucideIcons.edit3, 'Edit Profile', () {
              _navigateToEditProfile(context);
            }),
            _buildDrawerItem(LucideIcons.helpCircle, 'Help & Support', () {
              Navigator.pushNamed(context, '/support');
            }),
            _buildDrawerItem(LucideIcons.shield, 'Privacy Policy', () {
              Navigator.pushNamed(context, '/privacy');
            }),
            const Divider(color: Colors.white30),
            _buildDrawerItem(LucideIcons.logOut, 'Sign Out', () {
              _showSignOutDialog(context);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red[300] : Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red[300] : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1E293B),
      leading: IconButton(
        icon: const Icon(LucideIcons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Health Hub',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF3B82F6).withOpacity(0.9),
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: ModernPatternPainter(),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bell, color: Colors.white, size: 24),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        IconButton(
          icon: const Icon(LucideIcons.user, color: Colors.white, size: 24),
          onPressed: () => _navigateToProfile(context),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final List<QuickAction> actions = [
      QuickAction('Health Metrics', LucideIcons.activitySquare, '/health-metrics', const Color(0xFF10B981)),
      QuickAction('Book Appointment', LucideIcons.calendar, '/appointmentBooking', const Color(0xFF3B82F6)),
      QuickAction('Chat with Doctor', LucideIcons.messageCircle, '/chat', const Color(0xFF10B981)),
      QuickAction('Emergency', LucideIcons.alertCircle, '/emergencyContacts', const Color(0xFFEF4444)),
      QuickAction('Legal Support', LucideIcons.scale, '/legalSupport', const Color(0xFF8B5CF6)),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (action.route == '/health-metrics') {
                        if (!mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: const Text(
                                    'Health Metrics',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: const Color(0xFF2C3E50),
                                  leading: IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                body: SafeArea(
                                  child: HealthMetricsDashboard(
                                    userId: widget.userId,
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
                      } else {
                        if (!mounted) return;
                        Navigator.pushNamed(context, action.route);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: action.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: widget.userId)
                  .where('dateTime', isGreaterThanOrEqualTo: DateTime.now())
                  .orderBy('dateTime')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final appointments = snapshot.data?.docs ?? [];

                if (appointments.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointmentData = appointments[index].data() as Map<String, dynamic>;
                    final dateTime = (appointmentData['dateTime'] as Timestamp).toDate();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        title: Text(
                          appointmentData['patientName'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${DateFormat('MMM dd, yyyy').format(dateTime)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${appointmentData['session'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Service: ${appointmentData['serviceId'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointmentData['status']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            appointmentData['status'] ?? 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  Widget _buildMainServices(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildCalendarCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/calendar'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.calendarDays,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Check your schedule and appointments',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            switch (index) {
              case 1:
                Navigator.pushNamed(context, '/schedule');
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthChatScreen()),
                );
                break;
              case 3:
                Navigator.pushNamed(context, '/settings');
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E293B),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              activeIcon: Icon(LucideIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendar),
              activeIcon: Icon(LucideIcons.calendar),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.messageCircle),
              activeIcon: Icon(LucideIcons.messageCircle),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings),
              activeIcon: Icon(LucideIcons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyFAB() {
    return ScaleTransition(
      scale: _fadeAnimation,
      child: FloatingActionButton.extended(
        onPressed: () => _showEmergencyDialog(context),
        backgroundColor: const Color(0xFFEF4444),
        elevation: 4,
        highlightElevation: 8,
        icon: const Icon(LucideIcons.alertCircle, color: Colors.white, size: 24),
        label: const Text(
          'Emergency',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(LucideIcons.alertCircle, color: const Color(0xFFEF4444), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Emergency Services',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you need immediate assistance?',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 12),
              Text(
                'Our emergency team is available 24/7.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.phoneCall, size: 20),
              label: const Text(
                'Call Emergency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/emergencyContacts');
              },
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(LucideIcons.logOut, color: const Color(0xFFEF4444), size: 28),
              const SizedBox(width: 12),
              const Text('Sign Out'),
            ],
          ),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Sign Out'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, '/editProfile');
  }
}

// Modern Pattern Painter for background design
class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Data Models
class QuickAction {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  QuickAction(this.title, this.icon, this.route, this.color);
}