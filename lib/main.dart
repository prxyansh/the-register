import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/register_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/permission_setup_screen.dart';
import 'services/background_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background geofence checks
  await BackgroundScheduler.initialize();

  runApp(
    const ProviderScope(
      child: AttendanceTrackerApp(),
    ),
  );
}

class AttendanceTrackerApp extends StatelessWidget {
  const AttendanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      theme: RegisterTheme.lightTheme(),
      darkTheme: RegisterTheme.darkTheme(),
      home: const _AppStartup(),
    );
  }
}

/// Checks if onboarding + permission setup have been completed,
/// shows the appropriate screen.
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  bool? _onboardingComplete;
  bool? _permissionsSetup;

  @override
  void initState() {
    super.initState();
    _checkState();
  }

  Future<void> _checkState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      _permissionsSetup = prefs.getBool('permissions_setup') ?? false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      setState(() => _onboardingComplete = true);
    }
  }

  Future<void> _completePermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_setup', true);
    // Re-schedule today's classes now that permissions are set
    await BackgroundScheduler.scheduleChecksForToday();
    if (mounted) {
      setState(() => _permissionsSetup = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      // Still loading prefs
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_onboardingComplete == false) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    if (_permissionsSetup == false) {
      return PermissionSetupScreen(onComplete: _completePermissions);
    }

    return const _MainShell();
  }
}

/// Main app shell with bottom navigation bar.
/// Provides the primary navigation between Today, Timetable, and Reports.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    TodayScreen(),
    TimetableScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_rounded),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
