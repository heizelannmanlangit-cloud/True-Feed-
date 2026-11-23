import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truefeed/views/main_navigation.dart';

// Opens the app as a logged in User (the tests skip the Login screen)
Widget testApp({bool reviewer = false}) {
  return MaterialApp(
    home: MainNavigation(
      userId: 'test-user',
      userEmail: 'student@test.com',
      userName: 'Student',
      isReviewer: reviewer,
      onLogout: () {},
    ),
  );
}

void main() {
  setUp(() {
    // The tests run without a phone, so give shared_preferences empty data
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home feed shows articles and a card opens the article page',
      (tester) async {
    await tester.pumpWidget(testApp());

    // Home feed
    expect(find.text('TRUE FEED'), findsOneWidget);
    expect(find.text('Senate passes new tuition subsidy bill'), findsOneWidget);

    // Tap a card, the Article screen opens
    await tester.tap(find.text('Senate passes new tuition subsidy bill'));
    await tester.pumpAndSettle();
    expect(find.text('Article'), findsOneWidget);
    expect(find.text('92% match'), findsOneWidget);
    expect(find.text('Headline Check'), findsOneWidget);
  });

  testWidgets('bottom navigation switches screens', (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Search headlines or topics'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Why are you reporting this?'), findsOneWidget);
  });

  testWidgets('search finds a story by typing', (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'tuition');
    await tester.pumpAndSettle();
    expect(find.text('1 story found'), findsOneWidget);
  });

  testWidgets('saving a story shows it on the Saved tab', (tester) async {
    await tester.pumpWidget(testApp());

    // Open the first story and save it
    await tester.tap(find.text('Senate passes new tuition subsidy bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);

    // Go back and open the Saved tab
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();
    expect(find.text('Senate passes new tuition subsidy bill'), findsOneWidget);
  });

  testWidgets('only a reviewer sees the Reviews tab', (tester) async {
    await tester.pumpWidget(testApp());
    expect(find.text('Reviews'), findsNothing);

    await tester.pumpWidget(testApp(reviewer: true));
    await tester.pumpAndSettle();
    expect(find.text('Reviews'), findsOneWidget);
  });
}
