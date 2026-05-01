import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:feild_survey_app/dashboard.dart';

void main() {
  testWidgets('Dashboard displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    // Verify that the dashboard shows expected elements.
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Surveys'), findsOneWidget);
    expect(find.text('New Survey'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
