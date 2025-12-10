import 'package:flutter/material.dart';
import 'package:appflowy_board/appflowy_board.dart';

/// Stress test board widget for testing various edge cases
class StressTestBoard extends StatefulWidget {
  final StressTestConfig config;

  const StressTestBoard({
    super.key,
    required this.config,
  });

  @override
  State<StressTestBoard> createState() => StressTestBoardState();
}

class StressTestBoardState extends State<StressTestBoard> {
  late final AppFlowyBoardController controller;
  late final AppFlowyBoardScrollController boardScrollController;

  int moveCount = 0;
  int crossGroupMoveCount = 0;
  String? lastError;

  @override
  void initState() {
    super.initState();
    boardScrollController = AppFlowyBoardScrollController();
    controller = AppFlowyBoardController(
      onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        debugPrint('Group move: $fromGroupId -> $toGroupId');
      },
      onMoveGroupItem: (groupId, fromIndex, toIndex) {
        moveCount++;
        debugPrint('Item move within $groupId: $fromIndex -> $toIndex (total: $moveCount)');
      },
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        crossGroupMoveCount++;
        debugPrint('Cross-group move: $fromGroupId:$fromIndex -> $toGroupId:$toIndex (total: $crossGroupMoveCount)');
      },
    );

    _initializeBoard();
  }

  void _initializeBoard() {
    final config = widget.config;

    for (int g = 0; g < config.groupCount; g++) {
      final groupId = 'Group_$g';
      final groupName = config.longGroupNames
          ? 'Very Long Group Name That Should Overflow The Header Width - Group $g'
          : 'Group $g';

      final items = <AppFlowyGroupItem>[];

      for (int i = 0; i < config.cardsPerGroup; i++) {
        final cardId = '${groupId}_Card_$i';

        if (config.largeCardContent && i % 3 == 0) {
          items.add(LargeContentItem(
            id: cardId,
            title: 'Large Content Card $i',
            content: _generateLargeContent(config.largeContentLines),
          ));
        } else if (config.specialCharacters && i % 4 == 0) {
          items.add(SpecialCharItem(
            id: cardId,
            content: _generateSpecialCharContent(i),
          ));
        } else if (config.mixedCardHeights) {
          final lines = (i % 5) + 1;
          items.add(VariableHeightItem(
            id: cardId,
            title: 'Card $i',
            lines: lines,
          ));
        } else {
          items.add(SimpleItem(id: cardId, title: 'Card $i'));
        }
      }

      controller.addGroup(AppFlowyGroupData(
        id: groupId,
        name: groupName,
        items: items,
      ));
    }
  }

  String _generateLargeContent(int lines) {
    final buffer = StringBuffer();
    for (int i = 0; i < lines; i++) {
      buffer.writeln('This is line ${i + 1} of the large content. '
          'It contains enough text to demonstrate how the card handles '
          'multiple lines of content and potential overflow scenarios.');
    }
    return buffer.toString();
  }

  String _generateSpecialCharContent(int index) {
    final specialChars = [
      '🚀 Emoji Card: 🎉🔥💡✨🌟',
      '中文内容测试 - Chinese Text',
      'العربية - Arabic Text RTL',
      'Ελληνικά - Greek Characters',
      '日本語テスト - Japanese',
      'Código especial: <>&"\'\\n\\t',
      'Math: ∑∏∫√∞≠≈≤≥',
      'Symbols: ©®™℃℉°±×÷',
    ];
    return specialChars[index % specialChars.length];
  }

  void addCardToGroup(String groupId) {
    final groupController = controller.getGroupController(groupId);
    if (groupController != null) {
      final newId = '${groupId}_NewCard_${DateTime.now().millisecondsSinceEpoch}';
      groupController.add(SimpleItem(id: newId, title: 'New Card'));
    }
  }

  void removeFirstCardFromGroup(String groupId) {
    final groupController = controller.getGroupController(groupId);
    if (groupController != null && groupController.items.isNotEmpty) {
      groupController.removeAt(0);
    }
  }

  void clearGroup(String groupId) {
    final groupController = controller.getGroupController(groupId);
    if (groupController != null) {
      while (groupController.items.isNotEmpty) {
        groupController.removeAt(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Moves: $moveCount', key: const Key('move_count')),
              Text('Cross-group: $crossGroupMoveCount', key: const Key('cross_group_count')),
              Text('Groups: ${controller.groupDatas.length}', key: const Key('group_count')),
            ],
          ),
        ),
        // Board
        Expanded(
          child: AppFlowyBoard(
            controller: controller,
            boardScrollController: boardScrollController,
            cardBuilder: (context, group, groupItem) {
              return AppFlowyGroupCard(
                key: ValueKey(groupItem.id),
                child: _buildCard(groupItem),
              );
            },
            headerBuilder: (context, columnData) {
              return AppFlowyGroupHeader(
                title: Expanded(
                  child: Text(
                    columnData.headerData.groupName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    key: Key('header_${columnData.id}'),
                  ),
                ),
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
            footerBuilder: (context, columnData) {
              return AppFlowyGroupFooter(
                icon: const Icon(Icons.add, size: 20),
                title: widget.config.narrowGroups
                    ? const Text('Add', overflow: TextOverflow.ellipsis)
                    : Text('Add to ${columnData.id}', overflow: TextOverflow.ellipsis),
                height: 40,
                onAddButtonClick: () {
                  addCardToGroup(columnData.id);
                },
              );
            },
            groupConstraints: BoxConstraints.tightFor(
              width: widget.config.narrowGroups ? 150 : 240,
            ),
            config: AppFlowyBoardConfig(
              groupBackgroundColor: Colors.grey[100]!,
              stretchGroupHeight: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AppFlowyGroupItem item) {
    if (item is SimpleItem) {
      return Container(
        key: Key('card_${item.id}'),
        padding: const EdgeInsets.all(12),
        child: Text(item.title),
      );
    }

    if (item is LargeContentItem) {
      return Container(
        key: Key('card_${item.id}'),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              item.content,
              style: const TextStyle(fontSize: 12),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (item is SpecialCharItem) {
      return Container(
        key: Key('card_${item.id}'),
        padding: const EdgeInsets.all(12),
        child: Text(item.content),
      );
    }

    if (item is VariableHeightItem) {
      return Container(
        key: Key('card_${item.id}'),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate(
              item.lines,
              (i) => Text('Line ${i + 1}', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: const Text('Unknown item type'),
    );
  }
}

/// Configuration for stress test scenarios
class StressTestConfig {
  final int groupCount;
  final int cardsPerGroup;
  final bool largeCardContent;
  final int largeContentLines;
  final bool specialCharacters;
  final bool mixedCardHeights;
  final bool longGroupNames;
  final bool narrowGroups;

  const StressTestConfig({
    this.groupCount = 3,
    this.cardsPerGroup = 5,
    this.largeCardContent = false,
    this.largeContentLines = 10,
    this.specialCharacters = false,
    this.mixedCardHeights = false,
    this.longGroupNames = false,
    this.narrowGroups = false,
  });

  /// 100+ cards in a single group
  static const StressTestConfig largeGroup = StressTestConfig(
    groupCount: 1,
    cardsPerGroup: 100,
  );

  /// Many groups with moderate cards
  static const StressTestConfig manyGroups = StressTestConfig(
    groupCount: 20,
    cardsPerGroup: 10,
  );

  /// Large content cards
  static const StressTestConfig largeContent = StressTestConfig(
    groupCount: 3,
    cardsPerGroup: 20,
    largeCardContent: true,
    largeContentLines: 20,
  );

  /// Special characters and emoji
  static const StressTestConfig specialChars = StressTestConfig(
    groupCount: 3,
    cardsPerGroup: 15,
    specialCharacters: true,
  );

  /// Mixed card heights
  static const StressTestConfig mixedHeights = StressTestConfig(
    groupCount: 4,
    cardsPerGroup: 20,
    mixedCardHeights: true,
  );

  /// Long group names
  static const StressTestConfig longNames = StressTestConfig(
    groupCount: 5,
    cardsPerGroup: 10,
    longGroupNames: true,
  );

  /// Narrow groups
  static const StressTestConfig narrow = StressTestConfig(
    groupCount: 6,
    cardsPerGroup: 15,
    narrowGroups: true,
  );

  /// Empty groups
  static const StressTestConfig emptyGroups = StressTestConfig(
    groupCount: 5,
    cardsPerGroup: 0,
  );

  /// Single card per group
  static const StressTestConfig singleCards = StressTestConfig(
    groupCount: 5,
    cardsPerGroup: 1,
  );

  /// Extreme stress test: many groups, many cards
  static const StressTestConfig extreme = StressTestConfig(
    groupCount: 10,
    cardsPerGroup: 50,
    mixedCardHeights: true,
    largeCardContent: true,
    largeContentLines: 5,
  );
}

// Item types for stress testing
class SimpleItem extends AppFlowyGroupItem {
  @override
  final String id;
  final String title;

  SimpleItem({required this.id, required this.title});
}

class LargeContentItem extends AppFlowyGroupItem {
  @override
  final String id;
  final String title;
  final String content;

  LargeContentItem({
    required this.id,
    required this.title,
    required this.content,
  });
}

class SpecialCharItem extends AppFlowyGroupItem {
  @override
  final String id;
  final String content;

  SpecialCharItem({required this.id, required this.content});
}

class VariableHeightItem extends AppFlowyGroupItem {
  @override
  final String id;
  final String title;
  final int lines;

  VariableHeightItem({
    required this.id,
    required this.title,
    required this.lines,
  });
}
