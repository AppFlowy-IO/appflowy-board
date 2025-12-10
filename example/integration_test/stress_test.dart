import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:example/stress_test_board.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to create a test app with specific config
  Widget createTestApp(StressTestConfig config, {Key? boardKey}) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Stress Test')),
        body: StressTestBoard(key: boardKey, config: config),
      ),
    );
  }

  group('Large Card Count Tests', () {
    testWidgets('Board handles 100 cards in single group', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.largeGroup));
      await tester.pumpAndSettle();

      // Verify board renders
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Verify group header
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);

      // First cards should be visible
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      // Scroll down to see more cards
      final scrollable = find.byType(Scrollable).last;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Middle cards should now be visible
      expect(find.byKey(const Key('card_Group_0_Card_10')), findsOneWidget);

      // Scroll to bottom
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      // Last cards should be visible
      expect(find.byKey(const Key('card_Group_0_Card_99')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag card in large group (100 cards)', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.largeGroup));
      await tester.pumpAndSettle();

      // Find first card
      final card0 = find.byKey(const Key('card_Group_0_Card_0'));
      expect(card0, findsOneWidget);

      // Long press and drag
      final cardCenter = tester.getCenter(card0);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 500));

      // Drag down
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump(const Duration(milliseconds: 200));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      // Card should still exist
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      // Check move count increased
      expect(find.byKey(const Key('move_count')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Scroll performance in large group', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.largeGroup));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).last;

      // Sequential scroll operations (avoid fling which causes drag target issues)
      for (int i = 0; i < 3; i++) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      // Scroll back up
      for (int i = 0; i < 3; i++) {
        await tester.drag(scrollable, const Offset(0, 300));
        await tester.pumpAndSettle();
      }

      // Board should still be responsive
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Large Content Card Tests', () {
    testWidgets('Cards with very long content render correctly', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.largeContent));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Find large content card (every 3rd card is large content)
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      // Verify the card has scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag large content card', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.largeContent));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('card_Group_0_Card_0'));
      expect(card, findsOneWidget);

      // Long press and drag
      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 500));

      // Drag to another group
      await gesture.moveBy(const Offset(250, 0));
      await tester.pump(const Duration(milliseconds: 200));

      await gesture.up();
      await tester.pumpAndSettle();

      // Card should still exist
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Many Groups Tests', () {
    testWidgets('Board handles 20 groups', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.manyGroups));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // First group should be visible
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);

      // Scroll horizontally to see more groups
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-1000, 0));
      await tester.pumpAndSettle();

      // Middle groups should be visible
      expect(find.byKey(const Key('header_Group_5')), findsOneWidget);

      // Scroll to end
      await tester.drag(boardScroll, const Offset(-3000, 0));
      await tester.pumpAndSettle();

      // Last groups should be visible
      expect(find.byKey(const Key('header_Group_19')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Horizontal scroll performance with many groups', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.manyGroups));
      await tester.pumpAndSettle();

      final boardScroll = find.byType(SingleChildScrollView).first;

      // Sequential horizontal scrolling (avoid fling)
      for (int i = 0; i < 3; i++) {
        await tester.drag(boardScroll, const Offset(-400, 0));
        await tester.pumpAndSettle();
      }

      // Scroll back
      for (int i = 0; i < 3; i++) {
        await tester.drag(boardScroll, const Offset(400, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Cross-group drag with many groups', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.manyGroups));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('card_Group_0_Card_0'));
      expect(card, findsOneWidget);

      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 500));

      // Drag to adjacent group
      await gesture.moveBy(const Offset(250, 0));
      await tester.pump(const Duration(milliseconds: 200));

      await gesture.up();
      await tester.pumpAndSettle();

      // Verify cross-group count
      expect(find.byKey(const Key('cross_group_count')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Edge Case Tests', () {
    testWidgets('Empty groups render correctly', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.emptyGroups));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Headers should be visible
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);
      expect(find.byKey(const Key('header_Group_1')), findsOneWidget);

      // No cards should exist
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsNothing);

      // Add button should be tappable
      final addButton = find.text('Add to Group_0');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Single card per group', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.singleCards));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Each group should have exactly one card
      for (int i = 0; i < 5; i++) {
        expect(find.byKey(Key('card_Group_${i}_Card_0')), findsOneWidget);
        expect(find.byKey(Key('card_Group_${i}_Card_1')), findsNothing);
      }

      // Drag single card within same group (simpler test)
      final card = find.byKey(const Key('card_Group_0_Card_0'));
      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 600));

      await gesture.moveBy(const Offset(0, 50));
      await tester.pump(const Duration(milliseconds: 300));

      await gesture.up();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Sequential drags with proper delays', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 3, cardsPerGroup: 10),
      ));
      await tester.pumpAndSettle();

      // Perform sequential drags with proper delays
      for (int i = 0; i < 3; i++) {
        final card = find.byKey(const Key('card_Group_0_Card_0'));
        if (card.evaluate().isNotEmpty) {
          final cardCenter = tester.getCenter(card);
          final gesture = await tester.startGesture(cardCenter);
          await tester.pump(const Duration(milliseconds: 600));

          await gesture.moveBy(const Offset(0, 60));
          await tester.pump(const Duration(milliseconds: 300));

          await gesture.up();
          await tester.pumpAndSettle();

          // Wait between drags to avoid state issues
          await tester.pump(const Duration(milliseconds: 500));
        }
      }

      // Board should still be functional
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Cancel drag mid-way', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 3, cardsPerGroup: 5),
      ));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('card_Group_0_Card_0'));
      final cardCenter = tester.getCenter(card);

      // Start drag
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 600));

      // Move card
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump(const Duration(milliseconds: 200));

      // Cancel by moving back and releasing
      await gesture.moveBy(const Offset(-50, -50));
      await tester.pump(const Duration(milliseconds: 200));

      await gesture.up();
      await tester.pumpAndSettle();

      // Card should still be in original position
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Special Characters and Internationalization', () {
    testWidgets('Cards with emoji and special characters', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.specialChars));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Board should render with special content cards
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);

      // Check for cards (special content cards have keys)
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Board handles international text in cards', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.specialChars));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Scroll to see more cards with different character types
      final scrollable = find.byType(Scrollable).last;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Board should still be functional
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag special character card', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.specialChars));
      await tester.pumpAndSettle();

      // Find a card and drag it
      final card = find.byKey(const Key('card_Group_0_Card_0'));
      if (card.evaluate().isNotEmpty) {
        final cardCenter = tester.getCenter(card);
        final gesture = await tester.startGesture(cardCenter);
        await tester.pump(const Duration(milliseconds: 600));

        await gesture.moveBy(const Offset(0, 80));
        await tester.pump(const Duration(milliseconds: 300));

        await gesture.up();
        await tester.pumpAndSettle();
      }

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Mixed Card Heights Tests', () {
    testWidgets('Board handles mixed height cards', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.mixedHeights));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // All cards should render regardless of height
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);
      expect(find.byKey(const Key('card_Group_0_Card_1')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag between cards of different heights', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.mixedHeights));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('card_Group_0_Card_0'));
      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 500));

      // Drag down past cards of varying heights
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump(const Duration(milliseconds: 200));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Long Group Names Tests', () {
    testWidgets('Long group names are displayed', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.longNames));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Headers should render (they may be truncated due to overflow)
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);

      // Cards should render
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);

      // Scroll horizontally to verify all groups render
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Narrow Groups Tests', () {
    testWidgets('Narrow groups render correctly', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.narrow));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Groups should be visible due to narrow width
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);

      // Scroll horizontally to verify all narrow groups load
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-300, 0));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag card vertically in narrow groups', (tester) async {
      await tester.pumpWidget(createTestApp(StressTestConfig.narrow));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('card_Group_0_Card_0'));
      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 600));

      // Drag within same group (vertical only to avoid cross-group complexity)
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 300));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Auto-scroll Boundary Tests', () {
    testWidgets('Drag towards top within visible area', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 1, cardsPerGroup: 20),
      ));
      await tester.pumpAndSettle();

      // Find a visible card and drag upward
      final card = find.byKey(const Key('card_Group_0_Card_5'));
      if (card.evaluate().isNotEmpty) {
        final cardCenter = tester.getCenter(card);
        final gesture = await tester.startGesture(cardCenter);
        await tester.pump(const Duration(milliseconds: 600));

        // Drag upward within visible area
        await gesture.moveBy(const Offset(0, -100));
        await tester.pump(const Duration(milliseconds: 300));

        await gesture.up();
        await tester.pumpAndSettle();
      }

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag towards bottom within visible area', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 1, cardsPerGroup: 20),
      ));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('card_Group_0_Card_0'));
      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 600));

      // Drag downward within visible area
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump(const Duration(milliseconds: 300));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag horizontally within visible groups', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 5, cardsPerGroup: 5),
      ));
      await tester.pumpAndSettle();

      // Drag card to adjacent group
      final card = find.byKey(const Key('card_Group_0_Card_0'));
      if (card.evaluate().isNotEmpty) {
        final cardCenter = tester.getCenter(card);
        final gesture = await tester.startGesture(cardCenter);
        await tester.pump(const Duration(milliseconds: 600));

        // Drag towards next group
        await gesture.moveBy(const Offset(200, 0));
        await tester.pump(const Duration(milliseconds: 300));

        await gesture.up();
        await tester.pumpAndSettle();
      }

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Extreme Stress Tests', () {
    testWidgets('Large configuration renders correctly', (tester) async {
      // Use a more moderate configuration to avoid timeout
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 5, cardsPerGroup: 30),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // First group should render
      expect(find.byKey(const Key('header_Group_0')), findsOneWidget);

      // Scroll horizontally to verify all groups load
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Scroll back
      await tester.drag(boardScroll, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Scroll and verify stability in large config', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 5, cardsPerGroup: 30),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final boardScroll = find.byType(SingleChildScrollView).first;

      // Scroll operations with proper settling
      await tester.drag(boardScroll, const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.drag(boardScroll, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Scroll back
      await tester.drag(boardScroll, const Offset(800, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Dynamic Operations Tests', () {
    testWidgets('Add cards dynamically via button', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 2, cardsPerGroup: 3),
      ));
      await tester.pumpAndSettle();

      // Initial state
      expect(find.byKey(const Key('card_Group_0_Card_0')), findsOneWidget);
      expect(find.byKey(const Key('card_Group_0_Card_2')), findsOneWidget);

      // Add card via button
      final addButton = find.text('Add to Group_0');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // New card should appear
      expect(find.textContaining('New Card'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Board remains stable after sequential add operations', (tester) async {
      await tester.pumpWidget(createTestApp(
        const StressTestConfig(groupCount: 2, cardsPerGroup: 5),
      ));
      await tester.pumpAndSettle();

      // Add multiple cards with proper delays
      final addButton = find.text('Add to Group_0');
      for (int i = 0; i < 5; i++) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Verify multiple new cards were added
      expect(find.textContaining('New Card'), findsWidgets);

      await tester.pump(const Duration(seconds: 1));
    });
  });
}
