import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy_board/appflowy_board.dart';

/// Tests for issue #26: Auto-scroll should work when board is not full screen width
/// https://github.com/AppFlowy-IO/appflowy-board/issues/26
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Constrained Width Layout Tests (Issue #26)', () {
    testWidgets('Board works in Row with Expanded', (tester) async {
      final controller = AppFlowyBoardController(
        onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {},
        onMoveGroupItem: (groupId, fromIndex, toIndex) {},
        onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {},
      );

      // Create multiple groups with cards
      for (int g = 0; g < 5; g++) {
        final items = <AppFlowyGroupItem>[];
        for (int i = 0; i < 5; i++) {
          items.add(TextItem(id: 'G${g}_Card_$i', title: 'Group $g Card $i'));
        }
        controller.addGroup(AppFlowyGroupData(
          id: 'Group_$g',
          name: 'Group $g',
          items: items,
        ));
      }

      // Build board in constrained width layout (as reported in issue #26)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                // Side panel taking some space
                Container(
                  width: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Side Panel')),
                ),
                // Board in Expanded (not full width)
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: AppFlowyBoard(
                      controller: controller,
                      cardBuilder: (context, group, groupItem) {
                        final item = groupItem as TextItem;
                        return AppFlowyGroupCard(
                          key: ValueKey(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Text(item.title),
                          ),
                        );
                      },
                      headerBuilder: (context, columnData) {
                        return AppFlowyGroupHeader(
                          title: Text(columnData.headerData.groupName),
                          height: 50,
                        );
                      },
                      groupConstraints: const BoxConstraints.tightFor(width: 200),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify board renders correctly
      expect(find.byType(AppFlowyBoard), findsOneWidget);
      expect(find.text('Group 0'), findsOneWidget);
      expect(find.text('Group 0 Card 0'), findsOneWidget);

      // Verify horizontal scrolling works
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Should be able to see later groups after scrolling
      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Drag and drop works in constrained width', (tester) async {
      int moveCount = 0;
      final controller = AppFlowyBoardController(
        onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {},
        onMoveGroupItem: (groupId, fromIndex, toIndex) {
          moveCount++;
        },
        onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {},
      );

      // Create groups with cards
      for (int g = 0; g < 3; g++) {
        final items = <AppFlowyGroupItem>[];
        for (int i = 0; i < 5; i++) {
          items.add(TextItem(id: 'G${g}_Card_$i', title: 'G$g C$i'));
        }
        controller.addGroup(AppFlowyGroupData(
          id: 'Group_$g',
          name: 'Group $g',
          items: items,
        ));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Container(
                  width: 150,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: AppFlowyBoard(
                    controller: controller,
                    cardBuilder: (context, group, groupItem) {
                      final item = groupItem as TextItem;
                      return AppFlowyGroupCard(
                        key: ValueKey(item.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(item.title),
                        ),
                      );
                    },
                    headerBuilder: (context, columnData) {
                      return AppFlowyGroupHeader(
                        title: Text(columnData.headerData.groupName),
                        height: 40,
                      );
                    },
                    groupConstraints: const BoxConstraints.tightFor(width: 180),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and drag a card
      final card = find.text('G0 C0');
      expect(card, findsOneWidget);

      final cardCenter = tester.getCenter(card);
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 600));

      // Drag down within the same group
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 300));

      await gesture.up();
      await tester.pumpAndSettle();

      // Verify move happened
      expect(moveCount, greaterThan(0));

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Board in nested layout with padding', (tester) async {
      final controller = AppFlowyBoardController();

      for (int g = 0; g < 4; g++) {
        final items = <AppFlowyGroupItem>[];
        for (int i = 0; i < 3; i++) {
          items.add(TextItem(id: 'G${g}_$i', title: 'Item $i'));
        }
        controller.addGroup(AppFlowyGroupData(
          id: 'Group_$g',
          name: 'Column $g',
          items: items,
        ));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(32),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppFlowyBoard(
                    controller: controller,
                    cardBuilder: (context, group, groupItem) {
                      final item = groupItem as TextItem;
                      return AppFlowyGroupCard(
                        key: ValueKey(item.id),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(item.title),
                        ),
                      );
                    },
                    headerBuilder: (context, columnData) {
                      return AppFlowyGroupHeader(
                        title: Text(columnData.headerData.groupName),
                        height: 40,
                      );
                    },
                    groupConstraints: const BoxConstraints.tightFor(width: 160),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify board renders in nested layout
      expect(find.byType(AppFlowyBoard), findsOneWidget);
      expect(find.text('Column 0'), findsOneWidget);

      // Test scrolling
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Board with fixed width container', (tester) async {
      final controller = AppFlowyBoardController();

      for (int g = 0; g < 6; g++) {
        final items = <AppFlowyGroupItem>[];
        for (int i = 0; i < 4; i++) {
          items.add(TextItem(id: 'G${g}_$i', title: 'Card $i'));
        }
        controller.addGroup(AppFlowyGroupData(
          id: 'Group_$g',
          name: 'G$g',
          items: items,
        ));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: AppFlowyBoard(
                  controller: controller,
                  cardBuilder: (context, group, groupItem) {
                    final item = groupItem as TextItem;
                    return AppFlowyGroupCard(
                      key: ValueKey(item.id),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(item.title),
                      ),
                    );
                  },
                  headerBuilder: (context, columnData) {
                    return AppFlowyGroupHeader(
                      title: Text(columnData.headerData.groupName),
                      height: 36,
                    );
                  },
                  groupConstraints: const BoxConstraints.tightFor(width: 140),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyBoard), findsOneWidget);

      // Scroll to see more groups
      final boardScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(boardScroll, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Last groups should be reachable
      expect(find.text('G5'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });
}

class TextItem extends AppFlowyGroupItem {
  @override
  final String id;
  final String title;

  TextItem({required this.id, required this.title});
}
