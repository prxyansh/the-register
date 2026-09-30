import 'package:flutter/material.dart';

/// Onboarding screen — SPEC.md §10, Screen 1.
/// Explains that this is a personal self-tracker (not official),
/// and why it needs location access.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage(
                    context,
                    icon: Icons.track_changes_rounded,
                    iconColor: colorScheme.primary,
                    title: 'Auto Attendance Tracker',
                    subtitle: 'Your personal attendance companion',
                    body: 'Automatically tracks which classes you attend '
                        'using your phone\'s location — so you always know '
                        'where you stand.',
                  ),
                  _buildPage(
                    context,
                    icon: Icons.info_outline_rounded,
                    iconColor: colorScheme.tertiary,
                    title: 'Personal Tool Only',
                    subtitle: 'Not an official record',
                    body: 'This app is for your own awareness. It is NOT '
                        'connected to your college\'s attendance system and '
                        'is NOT submitted to faculty or administration.\n\n'
                        'Think of it as a personal diary for your classes.',
                  ),
                  _buildPage(
                    context,
                    icon: Icons.location_on_rounded,
                    iconColor: colorScheme.secondary,
                    title: 'Why Location Access?',
                    subtitle: 'Smart detection, not surveillance',
                    body: 'The app uses GPS to check if you\'re near your '
                        'classroom during scheduled class times — and ONLY '
                        'during those times.\n\n'
                        'No tracking outside class hours. No data leaves '
                        'your phone. Everything stays local.',
                  ),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String body,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
