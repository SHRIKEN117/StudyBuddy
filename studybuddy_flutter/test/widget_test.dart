import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_flutter/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pump();
    expect(find.byType(StudyBuddyApp), findsOneWidget);
  });
}
