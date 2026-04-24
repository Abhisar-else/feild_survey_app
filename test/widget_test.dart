
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feild_survey_app/dasboard.dart';

void main() {
  testWidgets('Dashboard displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FieldSurveyApp());

    // Verify that the dashboard shows expected elements.
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Surveys'), findsOneWidget);
    expect(find.text('New Survey'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
