import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_invitation/main.dart';
import 'package:date_invitation/models/date_invitation_data.dart';

void main() {
  testWidgets(
      'Full romantic date invitation flow rigs selection to Saturday @ 17:45 and Lestari Indonesisch Restaurant',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final jsonString = File('assets/date_options.json').readAsStringSync();
    final data = DateInvitationData.fromJsonString(jsonString);

    await tester.pumpWidget(RomanticDateApp(initialData: data));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Step 1: The Big Question
    expect(find.text(data.hero.title), findsOneWidget);
    expect(find.byKey(const Key('yes_button')), findsOneWidget);
    expect(find.byKey(const Key('no_button')), findsOneWidget);

    // Tap the "No" button and verify it evades and shows a pleading message
    await tester.ensureVisible(find.byKey(const Key('no_button')));
    await tester.tap(find.byKey(const Key('no_button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(data.hero.noButtonPleadingMessages.first),
      findsWidgets,
    );

    // Tap the "YES" button to advance to Step 2 (Pick a Date)
    await tester.ensureVisible(find.byKey(const Key('yes_button')));
    await tester.tap(find.byKey(const Key('yes_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Step 1: When Should I Pick You Up?'), findsOneWidget);
    expect(find.text('Saturday @ 17:45'), findsOneWidget);

    // Try tapping a decoy date ("Friday Night") -> verify it shows the rigged excuse and stays on Saturday @ 17:45
    await tester.ensureVisible(find.text('Friday Night'));
    await tester.pump();
    await tester.tap(find.text('Friday Night'));
    await tester.pump();
    expect(
      find.textContaining('Schedule Override'),
      findsWidgets,
    );

    // Advance to Step 3 (Pick a Restaurant)
    await tester.ensureVisible(find.byKey(const Key('to_restaurants_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('to_restaurants_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Step 2: What Are We Craving?'), findsOneWidget);
    expect(find.text('Lestari Indonesisch Restaurant'), findsOneWidget);

    // Advance to Step 4 (Final Date Ticket)
    await tester.ensureVisible(find.byKey(const Key('generate_ticket_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('generate_ticket_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('VIP ROMANTIC BOARDING PASS'), findsOneWidget);
    expect(find.textContaining('Lestari Indonesisch Restaurant'), findsWidgets);
    expect(find.textContaining('Saturday @ 17:45'), findsWidgets);
  });
}
