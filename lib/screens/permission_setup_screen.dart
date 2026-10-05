import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/location_service.dart';
import '../services/background_scheduler.dart';

/// Permission setup screen — SPEC.md §9.
///
/// Shown after onboarding and timetable setup when background tracking
/// is first enabled. Handles the permission escalation flow:
/// 1. Request "while in use" location
/// 2. Explain why background access is needed
/// 3. Request "always" location (background)
/// 4. Initialize the background scheduler
class PermissionSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionSetupScreen({super.key, required this.onComplete});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  int _step = 0; // 0=intro, 1=req fg, 2=req bg, 3=req battery, 4=done
  bool _foregroundGranted = false;
  bool _backgroundGranted = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    _foregroundGranted = await LocationService.hasForegroundPermission();
    _backgroundGranted = await LocationService.hasBackgroundPermission();
    if (_foregroundGranted && _backgroundGranted) {
      final isBatteryIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
      if (isBatteryIgnored) {
        _step = 4;
      } else {
        _step = 3;
      }
    } else if (_foregroundGranted) {
      _step = 2;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Setup'),
        actions: [
          TextButton(
            onPressed: _skipAndFinish,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildStep(theme),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildIntro(theme);
      case 1:
        return _buildRequestingForeground(theme);
      case 2:
        return _buildExplainBackground(theme);
      case 3:
        return _buildBatteryOptimization(theme);
      case 4:
        return _buildDone(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBatteryOptimization(ThemeData theme) {
    return Column(
      key: const ValueKey(3),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.battery_alert_rounded,
          size: 80,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(
          'Unrestricted Battery',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Android puts background apps to sleep to save battery. '
          'To ensure the auto-tracker never misses a class, you MUST '
          'allow unrestricted battery usage.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _isRequesting ? null : () async {
            setState(() => _isRequesting = true);
            var status = await Permission.ignoreBatteryOptimizations.request();
            if (!status.isGranted) {
              await openAppSettings();
              status = await Permission.ignoreBatteryOptimizations.status;
            }
            if (mounted) {
              setState(() {
                _isRequesting = false;
                _step = 4;
              });
            }
          },
          icon: _isRequesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.settings_suggest_rounded),
          label: const Text('Allow Background Execution'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 4),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Column(
      key: const ValueKey(0),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Location Access',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'To detect if you\'re at your class venue, the app needs '
          'location access. We\'ll start with "while using the app" '
          'permission.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shield_rounded,
                    color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your location data stays 100% on your device. '
                    'No server, no cloud, no tracking.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _isRequesting ? null : _requestForeground,
          icon: _isRequesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.location_searching_rounded),
          label: const Text('Grant Location Access'),
        ),
      ],
    );
  }

  Widget _buildRequestingForeground(ThemeData theme) {
    return Center(
      key: const ValueKey(1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Requesting permission...', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildExplainBackground(ThemeData theme) {
    return Column(
      key: const ValueKey(2),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 80,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 24),
        Text(
          'Background Access',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'For automatic attendance detection, the app needs to '
          'check your location during class times — even when the '
          'app isn\'t open.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.battery_saver_rounded,
                        color: theme.colorScheme.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location checks happen ONLY during your '
                        'scheduled class times — not continuously.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: theme.colorScheme.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Typically just 2 quick checks per class '
                        '(start and end), using minimal battery.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _isRequesting ? null : _requestBackground,
          icon: _isRequesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Allow Background Location'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skipAndFinish,
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildDone(ThemeData theme) {
    return Column(
      key: const ValueKey(4),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'All Set!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _backgroundGranted
              ? 'Background tracking is enabled. The app will '
                  'automatically check your attendance during class times.'
              : 'Foreground tracking is enabled. Open the app during '
                  'class to record attendance. You can enable background '
                  'tracking later in Settings.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _finish,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Start Tracking'),
        ),
      ],
    );
  }

  Future<void> _requestForeground() async {
    setState(() {
      _isRequesting = true;
      _step = 1;
    });

    _foregroundGranted = await LocationService.requestForegroundPermission();

    if (mounted) {
      setState(() {
        _isRequesting = false;
        _step = _foregroundGranted ? 2 : 0;
      });
    }
  }

  Future<void> _requestBackground() async {
    setState(() => _isRequesting = true);

    _backgroundGranted = await LocationService.requestBackgroundPermission();
    final isBatteryIgnored = await Permission.ignoreBatteryOptimizations.isGranted;

    if (mounted) {
      setState(() {
        _isRequesting = false;
        _step = isBatteryIgnored ? 4 : 3;
      });
    }
  }

  Future<void> _skipAndFinish() async {
    await _initializeScheduler();
    widget.onComplete();
  }

  Future<void> _finish() async {
    await _initializeScheduler();
    widget.onComplete();
  }

  Future<void> _initializeScheduler() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    await BackgroundScheduler.initialize();
    if (_foregroundGranted || _backgroundGranted) {
      await BackgroundScheduler.scheduleDailyPlanner();
      await BackgroundScheduler.scheduleChecksForToday();
    }
  }
}
