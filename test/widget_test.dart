import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/main.dart';

void main() {
  testWidgets('App smoke test - renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceTrackerApp());
    // Just pump a few frames — SharedPreferences async loading means
    // we see a loading spinner first, then onboarding
    await tester.pump(const Duration(seconds: 1));

    // The app should render without crashing
    expect(find.byType(AttendanceTrackerApp), findsOneWidget);
  });
}
