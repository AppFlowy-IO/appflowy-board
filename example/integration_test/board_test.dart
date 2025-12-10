import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart' as app;
import 'package:appflowy_board/appflowy_board.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AppFlowy Board Integration Tests', () {
    testWidgets('App launches and displays board', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app title
      expect(find.text('AppFlowy Board'), findsOneWidget);

      // Verify bottom navigation exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify board is displayed
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Take a screenshot moment - wait for user to see
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Board displays multiple groups with cards', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify cards are visible
      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);

      // Verify multiple groups exist by checking for different cards
      expect(find.text('Card 6'), findsOneWidget); // In Progress group

      // Wait to show the UI
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Navigate between board examples', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should start on MultiColumn tab
      expect(find.text('MultiColumn'), findsOneWidget);

      // Tap on SingleColumn tab
      await tester.tap(find.text('SingleColumn'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Verify we're on single column view
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Tap on MultiShrinkwrapColumn tab
      await tester.tap(find.text('MultiShrinkwrapColumn '));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Verify board is still displayed
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Go back to MultiColumn
      await tester.tap(find.text('MultiColumn'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Board cards are tappable', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap on a card
      final card1 = find.text('Card 1');
      expect(card1, findsOneWidget);

      await tester.tap(card1);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Card should still be visible after tap
      expect(find.text('Card 1'), findsOneWidget);
    });

    testWidgets('Board horizontal scroll works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the scrollable area (SingleChildScrollView inside AppFlowyBoard)
      final scrollable = find.byType(SingleChildScrollView).first;

      // Perform horizontal scroll
      await tester.drag(scrollable, const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Scroll back
      await tester.drag(scrollable, const Offset(200, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Group footer New button is visible and tappable',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find "New" buttons (footers)
      final newButtons = find.text('New');
      expect(newButtons, findsWidgets);

      // Tap on the first "New" button
      await tester.tap(newButtons.first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Long press on card initiates drag feedback', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find a card to drag
      final card = find.text('Card 1');
      expect(card, findsOneWidget);

      // Long press to start drag
      await tester.longPress(card);
      await tester.pump(const Duration(milliseconds: 500));

      // The drag feedback should appear (card is being dragged)
      // Release the drag
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag card within same group', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find Card 1
      final card1 = find.text('Card 1');
      expect(card1, findsOneWidget);

      // Get the center of Card 1
      final card1Center = tester.getCenter(card1);

      // Perform long press drag down (within same group)
      final gesture = await tester.startGesture(card1Center);
      await tester.pump(const Duration(milliseconds: 500)); // Long press delay

      // Drag down
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Card should still exist
      expect(find.text('Card 1'), findsOneWidget);
    });

    testWidgets('Drag card to another group', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find Card 1 (in "To Do" group)
      final card1 = find.text('Card 1');
      expect(card1, findsOneWidget);

      // Get the center of Card 1
      final card1Center = tester.getCenter(card1);

      // Perform long press drag to the right (to another group)
      final gesture = await tester.startGesture(card1Center);
      await tester.pump(const Duration(milliseconds: 500)); // Long press delay

      // Drag to the right (towards "In Progress" group)
      await gesture.moveBy(const Offset(250, 0));
      await tester.pump(const Duration(milliseconds: 200));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Card should still exist somewhere
      expect(find.text('Card 1'), findsOneWidget);
    });

    testWidgets('Rich text cards display title and subtitle', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find rich text card
      expect(find.text('Card 3'), findsOneWidget);
      expect(find.text('Aug 1, 2020 4:05 PM'), findsWidgets);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Group headers display group names', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Headers should show group names in TextFields
      // The text fields contain the group names
      expect(find.byType(TextField), findsWidgets);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('SingleColumn example displays correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to SingleColumn
      await tester.tap(find.text('SingleColumn'));
      await tester.pumpAndSettle();

      // Verify board is displayed
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // SingleColumn example has items a, b, c, d
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
      expect(find.text('d'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Shrinkwrap example displays correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to MultiShrinkwrapColumn
      await tester.tap(find.text('MultiShrinkwrapColumn '));
      await tester.pumpAndSettle();

      // Verify board is displayed
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Should have cards visible
      expect(find.text('Card 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Full user flow - navigate and interact', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // 1. View MultiColumn board
      expect(find.text('Card 1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Scroll horizontally to see more groups
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Scroll back
      await tester.drag(scrollable, const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Try to drag a card
      final card2 = find.text('Card 2');
      final card2Center = tester.getCenter(card2);
      final gesture = await tester.startGesture(card2Center);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Navigate to SingleColumn
      await tester.tap(find.text('SingleColumn'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // 6. Verify single column items
      expect(find.text('a'), findsOneWidget);

      // 7. Navigate to Shrinkwrap
      await tester.tap(find.text('MultiShrinkwrapColumn '));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // 8. Back to MultiColumn
      await tester.tap(find.text('MultiColumn'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Final verification
      expect(find.byType(AppFlowyBoard), findsOneWidget);
    });
  });
}
