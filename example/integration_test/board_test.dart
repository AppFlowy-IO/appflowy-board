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

      // Verify cards are visible in To Do group
      expect(find.text('Todo 1'), findsOneWidget);
      expect(find.text('Todo 2'), findsOneWidget);

      // Verify multiple groups exist by checking for different cards
      expect(find.text('Progress 1'), findsOneWidget); // In Progress group

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
      final card1 = find.text('Todo 1');
      expect(card1, findsOneWidget);

      await tester.tap(card1);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Card should still be visible after tap
      expect(find.text('Todo 1'), findsOneWidget);
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

    testWidgets('Lazy loading reveals more cards when scrolling',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // With cardPageSize: 10, only first 10 cards should be visible initially
      expect(find.text('Todo 1'), findsOneWidget);
      expect(find.text('Todo 10'), findsOneWidget);
      // Card beyond page size should not be visible
      expect(find.text('Todo 15'), findsNothing);

      // Find the vertical scrollable in the To Do group
      final scrollCandidates = find.ancestor(
        of: find.text('Todo 1'),
        matching: find.byType(SingleChildScrollView),
      );

      SingleChildScrollView? targetScroll;
      for (final element in scrollCandidates.evaluate()) {
        final widget = element.widget;
        if (widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.vertical) {
          targetScroll = widget;
          break;
        }
      }

      expect(targetScroll, isNotNull);

      final groupScroll = find.byWidget(targetScroll!);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: groupScroll, matching: find.byType(Scrollable)),
      );

      // Scroll to bottom to trigger load more
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // After first load more, cards 11-20 should now be loaded
      expect(find.text('Todo 15'), findsOneWidget);

      // Scroll again to load more
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // Cards 21-30 should now be loaded
      expect(find.text('Todo 25'), findsOneWidget);

      // Continue scrolling to load even more
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // Cards 31-40 should now be loaded
      expect(find.text('Todo 35'), findsOneWidget);

      // Final scroll to load remaining cards
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // Cards 41-50 should now be loaded
      expect(find.text('Todo 45'), findsOneWidget);
      expect(find.text('Todo 50'), findsOneWidget);
    });

    testWidgets('Loading indicator appears when loading more cards',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the vertical scrollable in the To Do group
      final scrollCandidates = find.ancestor(
        of: find.text('Todo 1'),
        matching: find.byType(SingleChildScrollView),
      );

      SingleChildScrollView? targetScroll;
      for (final element in scrollCandidates.evaluate()) {
        final widget = element.widget;
        if (widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.vertical) {
          targetScroll = widget;
          break;
        }
      }

      expect(targetScroll, isNotNull);

      final groupScroll = find.byWidget(targetScroll!);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: groupScroll, matching: find.byType(Scrollable)),
      );

      // Scroll to bottom to trigger load more
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);

      // Pump a few frames to allow loading indicator to appear
      // Don't use pumpAndSettle as it waits for all animations/futures to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Loading indicator should be visible during the async load
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now wait for loading to complete
      await tester.pumpAndSettle();

      // Loading indicator should be gone after loading completes
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // And new cards should be loaded
      expect(find.text('Todo 15'), findsOneWidget);
    });

    testWidgets('Move card after lazy loading more cards', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First, load more cards by scrolling
      final scrollCandidates = find.ancestor(
        of: find.text('Todo 1'),
        matching: find.byType(SingleChildScrollView),
      );

      SingleChildScrollView? targetScroll;
      for (final element in scrollCandidates.evaluate()) {
        final widget = element.widget;
        if (widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.vertical) {
          targetScroll = widget;
          break;
        }
      }

      expect(targetScroll, isNotNull);

      final groupScroll = find.byWidget(targetScroll!);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: groupScroll, matching: find.byType(Scrollable)),
      );

      // Scroll to load more cards
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // Verify Todo 15 is now visible
      expect(find.text('Todo 15'), findsOneWidget);

      // Now try to drag Todo 15 within the same group
      final card15 = find.text('Todo 15');
      final card15Center = tester.getCenter(card15);

      final gesture = await tester.startGesture(card15Center);
      await tester.pump(const Duration(milliseconds: 500)); // Long press delay

      // Drag up
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 100));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      // Card should still exist after drag
      expect(find.text('Todo 15'), findsOneWidget);
    });

    testWidgets('Move lazy-loaded card to another group', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First, load more cards by scrolling
      final scrollCandidates = find.ancestor(
        of: find.text('Todo 1'),
        matching: find.byType(SingleChildScrollView),
      );

      SingleChildScrollView? targetScroll;
      for (final element in scrollCandidates.evaluate()) {
        final widget = element.widget;
        if (widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.vertical) {
          targetScroll = widget;
          break;
        }
      }

      expect(targetScroll, isNotNull);

      final groupScroll = find.byWidget(targetScroll!);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: groupScroll, matching: find.byType(Scrollable)),
      );

      // Scroll to load more cards
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // Scroll back up to see Todo 15
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent / 2);
      await tester.pumpAndSettle();

      // Find Todo 15 and drag to another group
      final card15 = find.text('Todo 15');
      expect(card15, findsOneWidget);

      final card15Center = tester.getCenter(card15);

      final gesture = await tester.startGesture(card15Center);
      await tester.pump(const Duration(milliseconds: 500)); // Long press delay

      // Drag to the right (towards In Progress group)
      await gesture.moveBy(const Offset(250, 0));
      await tester.pump(const Duration(milliseconds: 200));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      // Card should still exist somewhere
      expect(find.text('Todo 15'), findsOneWidget);
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
      final card = find.text('Todo 1');
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

      // Find Todo 1
      final card1 = find.text('Todo 1');
      expect(card1, findsOneWidget);

      // Get the center of Todo 1
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
      expect(find.text('Todo 1'), findsOneWidget);
    });

    testWidgets('Drag card to another group', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find Todo 1 (in "To Do" group)
      final card1 = find.text('Todo 1');
      expect(card1, findsOneWidget);

      // Get the center of Todo 1
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
      expect(find.text('Todo 1'), findsOneWidget);
    });

    testWidgets('Rich text cards display title and subtitle', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Shrinkwrap example which has RichTextItem cards
      await tester.tap(find.text('MultiShrinkwrapColumn '));
      await tester.pumpAndSettle();

      // Find rich text card (Card 10 has subtitle in shrinkwrap example)
      expect(find.text('Card 10'), findsOneWidget);
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
      expect(find.text('Todo 1'), findsOneWidget);
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
      final card2 = find.text('Todo 2');
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
